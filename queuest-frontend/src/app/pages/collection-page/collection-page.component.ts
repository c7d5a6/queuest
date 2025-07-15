import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, Data} from '@angular/router';
import {BreakpointsService} from '../../services/breakpoints.service';
import {Item} from '../../api/models/item';
import {Collection} from '../../api/models/collection';
import {ItemsService} from '../../api/services/items.service';
import {DialogService} from "@ngneat/dialog";
import {CalibrateItemComponent} from "../../components/calibrate-item/calibrate-item.component";
import {CollectionsService} from "../../api/services/collections.service";
import {CollectionWithItems} from "../../api/models/collection-with-items";
import {AddCollectionComponent} from "../../components/add-collection/add-collection.component";
import {AddItemComponent} from "../../components/add-item/add-item.component";
import {CalibrateCollectionComponent} from "../../components/calibrate-collection/calibrate-collection.component";

@Component({
  selector: 'app-collection-page',
  templateUrl: './collection-page.component.html',
  styleUrls: ['./collection-page.component.scss'],
})
export class CollectionPageComponent implements OnInit {
  items: Array<Item> = [];
  calibrated: number = 0;
  collection!: Collection;

  constructor(
    private breakpointsService: BreakpointsService,
    private activatedRoute: ActivatedRoute,
    private itemService: ItemsService,
    private dialogService: DialogService,
    private collectionsService: CollectionsService,
  ) {
  }

  get itemsjson(): string {
    return JSON.stringify(this.items);
  }

  ngOnInit(): void {
    this.activatedRoute.data.subscribe((routeData: Data) => {
      const data = routeData as {
        items: CollectionWithItems;
        collection: Collection;
      };
      if (data && data.items) {
        this.items = data.items.items;
        this.calibrated = data.items.calibrated!;
        this.collection = data.collection;
        this.collectionsService.collectionControllerVisitCollection({collectionId: this.collection.id!}).subscribe(() => console.log("visited"));
      }
    });
  }

  calibrateItem(id: number) {
    this.dialogService
      .open(CalibrateItemComponent, {
        // data is typed based on the passed generic
        data: {
          title: `Calibrate`,
          itemId: id,
        },
      })
      .afterClosed$.subscribe(() =>
      this.reload());
  }

  calibrateCollection() {
    this.dialogService
      .open(CalibrateCollectionComponent, {
        // data is typed based on the passed generic
        data: {
          title: `Calibrate`,
          collectionId: this.collection.id,
        },
      })
      .afterClosed$.subscribe(() =>
      this.reload());
  }

  deleteItem(itemId: number | undefined) {
    if (!itemId) {
      return;
    }
    console.log("deleteItem", itemId);
    this.itemService
      .itemsControllerDeleteItemFromCollection({collectionId: this.collection.id!, collectionItemId: itemId})
      .subscribe(() => this.reload());

  }

  addToFavs() {
    this.collectionsService
      .collectionControllerAddCollectionToFav({collectionId: this.collection.id!})
      .subscribe(() => this.collection.favourite_yn = true);
  }

  addItem(): void {
    this.dialogService
      .open(AddItemComponent, {
        // data is typed based on the passed generic
        data: {
          title: 'Add Item',
          collectionId: this.collection.id!,
        },
      })
      .afterClosed$.subscribe((id: number|undefined) => {if(id) this.calibrateItem(id)});
  }

  removeFromFavs() {
    this.collectionsService
      .collectionControllerRemoveCollectionFromFav({collectionId: this.collection.id!})
      .subscribe(() => this.collection.favourite_yn = false);
  }

  private reload() {
    return this.itemService.itemsControllerGetItems({
      collectionId: this.collection.id!,
    }).subscribe((items) => {
      this.items = items.items;
      this.calibrated = items.calibrated!
    });
  }
}
