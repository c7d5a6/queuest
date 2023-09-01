import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Data } from '@angular/router';
import { BreakpointsService } from '../../services/breakpoints.service';
import { Item } from '../../api/models/item';
import { Collection } from '../../api/models/collection';
import { ItemsService } from '../../api/services/items.service';

@Component({
    selector: 'app-collection-page',
    templateUrl: './collection-page.component.html',
    styleUrls: ['./collection-page.component.scss'],
})
export class CollectionPageComponent implements OnInit {
    items: Array<Item> = [];
    collection!: Collection;

    constructor(
        private breakpointsService: BreakpointsService,
        private activatedRoute: ActivatedRoute,
        private itemService: ItemsService,
    ) {}

    get itemsjson(): string {
        return JSON.stringify(this.items);
    }

    ngOnInit(): void {
        this.activatedRoute.data.subscribe((routeData: Data) => {
            const data = routeData as {
                items: Array<Item>;
                collection: Collection;
            };
            if (data && data.items) {
                this.items = data.items;
                this.collection = data.collection;
            }
        });
    }

    itemAdded() {
        this.itemService
            .itemsControllerGetItems({
                collectionId: this.collection.id!,
            })
            .subscribe((items) => (this.items = items));
    }
}
