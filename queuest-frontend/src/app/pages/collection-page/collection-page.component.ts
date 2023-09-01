import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, Data} from '@angular/router';
import {BreakpointsService} from '../../services/breakpoints.service';
import {Item} from '../../api/models/item';
import {Collection} from '../../api/models/collection';
import {ItemsService} from '../../api/services/items.service';
import {AddCollectionComponent} from "../../components/add-collection/add-collection.component";
import {DialogService} from "@ngneat/dialog";
import {CalibrateItemComponent} from "../../components/calibrate-item/calibrate-item.component";

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
    private dialogService: DialogService,
  ) {
  }

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
    this.dialogService
      .open(CalibrateItemComponent, {
        // data is typed based on the passed generic
        data: {
          title: 'Calibrate item',
        },
      })
      .afterClosed$.subscribe(() =>
      this.itemService.itemsControllerGetItems({
        collectionId: this.collection.id!,
      }).subscribe((items) => (this.items = items)));
  }
}
