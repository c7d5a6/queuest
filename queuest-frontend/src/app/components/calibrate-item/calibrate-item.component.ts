import {
  Component, OnInit,
} from '@angular/core';
import {ItemsService} from '../../api/services/items.service';
import {DialogRef} from "@ngneat/dialog";
import {Data} from "@angular/router";
import {ItemPair} from "../../api/models/item-pair";

@Component({
  selector: 'app-calibrate-item',
  templateUrl: './calibrate-item.component.html',
  styleUrls: ['./calibrate-item.component.scss'],
})
export class CalibrateItemComponent implements OnInit {

  itemId: number | undefined;
  title: string = '';
  items: ItemPair[] = [];
  calibrated = false;

  constructor(
    private ref: DialogRef<Data>,
    private itemsService: ItemsService,
  ) {
    console.log(ref.data);
    if(ref.data['title']){
      this.title = ref.data['title']
    }
    if(ref.data['itemId']){
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
            } else {
                this.calibrated = true;
            }
            console.log(pair,this.items.length)
        });
  }

  ngOnInit(): void {
    this.getNextBestPair();
  }

  close() {
    this.ref.close();
  }
}
