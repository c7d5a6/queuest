import {
  Component, OnInit,
} from '@angular/core';
import {ItemsService} from '../../api/services/items.service';
import {DialogRef} from "@ngneat/dialog";
import {Data} from "@angular/router";
import {ItemPair} from "../../api/models/item-pair";
import {ItemsRelationService} from "../../api/services/items-relation.service";

@Component({
  selector: 'app-calibrate-item',
  templateUrl: './calibrate-item.component.html',
  styleUrls: ['./calibrate-item.component.scss'],
})
export class CalibrateItemComponent implements OnInit {

  itemId: number | undefined;
  collectionId: number | undefined;
  title: string = '';
  items: ItemPair[] = [];
  calibrated = true;

  constructor(
    private ref: DialogRef<Data>,
    private itemsService: ItemsService,
    private itemsRelationService: ItemsRelationService
  ) {
    console.log(ref.data);
    if (ref.data['title']) {
      this.title = ref.data['title']
    }
    if ('itemId' in ref.data) {
      this.itemId = this.toNumberOrUndefined(ref.data['itemId']);
    }
    if ('collectionId' in ref.data) {
      this.collectionId = this.toNumberOrUndefined(ref.data['collectionId']);
    }
  }

  getPairs() {
    this.getNextBestPair();
  }

  itemPressed(id: number) {
    if (id === this.items.length - 1) {
      this.getNextBestPair();
    }
  }

  getNextBestPair() {
    if (this.collectionId === undefined || this.itemId === undefined) {
      console.error('Invalid calibration request params', {
        collectionId: this.collectionId,
        itemId: this.itemId,
        data: this.ref.data,
      });
      return;
    }
    const ids: number[] = [];
    ids.push(this.itemId);
    this.items.forEach((item) => ids.push(item.item2.id!));
    console.log("calibrating item",this.collectionId, this.itemId, ids);
    this.itemsService
      .itemsControllerGetBestPair({
        collectionId: this.collectionId,
        collectionItemId: this.itemId,
        exclude: ids,
        strict: true
      })
      .subscribe((pair) => {
        if (!!pair) {
          this.items.push(pair);
          this.calibrated = false;
        } else {
          this.calibrated = true;
        }
        console.log(pair, this.items.length)
      });
  }

  ngOnInit(): void {
    this.getNextBestPair();
  }

  close() {
    this.ref.close();
  }

  addRelation(pair: ItemPair, i: number, from: number | undefined, to: number | undefined) {
    if (from !== undefined && to !== undefined) {
      console.log('adding relation');
      const relation = {
        from: from,
        to: to,
      };
      this.itemsRelationService
        .itemRelationsControllerAddItem({
          fromId: from,
          toId: to
        })
        .subscribe(() => {
          pair.relation = relation;
          this.itemPressed(i);
        });
    }
  }

  deleteRelation(pair: ItemPair, i: number) {
    console.log('deleting relation');
    if (pair.relation) {
      this.itemsRelationService
        .itemRelationsControllerGetItems({
          itemAId: pair.relation.from,
          itemBId: pair.relation.to
        })
        .subscribe(() => {
          pair.relation = undefined;
          this.itemPressed(i);
        });
    }
  }

  private toNumberOrUndefined(value: unknown): number | undefined {
    const n = Number(value);
    return Number.isFinite(n) ? n : undefined;
  }
}
