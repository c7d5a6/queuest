import {Component, Input, OnInit} from '@angular/core';
import {Collection} from '../../../api/models/collection';
import {ItemsService} from "../../../api/services/items.service";
import {Item} from "../../../api/models/item";
import {CollectionsService} from "../../../api/services/collections.service";

@Component({
  selector: 'app-collection-card',
  templateUrl: './collection-card.component.html',
  styleUrls: ['./collection-card.component.scss'],
})
export class CollectionCardComponent implements OnInit {

  @Input() collection!: Collection;
  items: Item[] = [];

  constructor(private itemsService: ItemsService, ) {
  }

  ngOnInit(): void {
    this.itemsService
      .itemsControllerGetItems({collectionId: this.collection.id!})
      .subscribe(items => {
        this.items = items.slice(0, 5);
      })
  }
}
