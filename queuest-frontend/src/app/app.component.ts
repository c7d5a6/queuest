import { Component, Input, OnInit } from '@angular/core';
import { ItemsService } from './api/services/items.service';
import { ItemEntity } from './api/models/item-entity';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
    items: ItemEntity[] = [];
    lastItem?: ItemEntity;

    constructor(private itemsService: ItemsService) {}

    ngOnInit(): void {
        this.reloadItems();
    }

    reloadItems() {
        this.getItems();
        this.getLastItem();
    }

    getItems() {
        this.itemsService
            .itemsControllerGetItems()
            .subscribe((value) => (this.items = value));
    }

    getLastItem() {
        this.itemsService
            .itemsControllerGetLastItem()
            .subscribe((value) => (this.lastItem = value));
    }
}
