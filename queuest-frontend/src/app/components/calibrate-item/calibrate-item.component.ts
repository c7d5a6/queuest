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
    if (ref.data['itemId']) {
      this.itemId = ref.data['itemId']
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
    const ids: number[] = [];
    ids.push(this.itemId!);
    this.items.forEach((item) => ids.push(item.item2.id!));
    this.itemsService
      .itemsControllerGetBestPair({
        id: this.itemId!,
        exclude: ids,
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
}
