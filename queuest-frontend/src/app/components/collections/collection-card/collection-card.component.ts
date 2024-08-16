import {Component, Input, OnInit} from '@angular/core';
import {Collection} from '../../../api/models/collection';
import {ItemsService} from "../../../api/services/items.service";
import {Item} from "../../../api/models/item";
import {CollectionsService} from "../../../api/services/collections.service";
import { Router } from '@angular/router';

@Component({
  selector: 'app-collection-card',
  templateUrl: './collection-card.component.html',
  styleUrls: ['./collection-card.component.scss'],
})
export class CollectionCardComponent implements OnInit {

  @Input() collection!: Collection;
  items: Item[] = [];

  constructor(
    private itemsService: ItemsService,
    private router: Router
  ) {
  }

  navigate(collectionId: number | undefined): void {
    this.router.navigate(['collection', collectionId]);
  }

  ngOnInit(): void {
    this.itemsService
      .itemsControllerGetItems({collectionId: this.collection.id!})
      .subscribe(items => {
        this.items = items.items.slice(0, 5);
      })
  }
}
