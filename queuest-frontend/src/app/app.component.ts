import { Component, OnInit } from '@angular/core';
import { ItemsService } from './api/services/items.service';
import { Item } from './api/models/item';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
    // items: Item[] = [];
    // lastItem?: Item;

    constructor() {}

    ngOnInit(): void {
        // this.reloadItems();
    }

    // reloadItems() {
    //   this.getItems();
    //   this.getLastItem();
    // }
    //
    // getItems() {
    //   // this.itemsService
    //   //     .itemsControllerGetItems()
    //   //     .subscribe((value) => (this.items = value));
    // }
    //
    // getLastItem() {
    //   // this.itemsService
    //   //     .itemsControllerGetLastItem()
    //   //     .subscribe((value) => (this.lastItem = value));
    // }
}
