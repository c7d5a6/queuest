import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, Data} from '@angular/router';
import {BreakpointsService} from '../../services/breakpoints.service';
import {Item} from '../../api/models/item';
import {Collection} from '../../api/models/collection';
import {ItemsService} from '../../api/services/items.service';
import {DialogService} from "@ngneat/dialog";
import {CalibrateItemComponent} from "../../components/calibrate-item/calibrate-item.component";
import {CollectionsService} from "../../api/services/collections.service";

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
    private collectionsService: CollectionsService,
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
        this.collectionsService.collectionControllerVisitCollection({collectionId:this.collection.id!}).subscribe(()=>console.log("visited"));
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

  deleteItem(itemId: number | undefined) {
    if (!itemId) {
      return;
    }
    this.itemService
      .itemsControllerDeleteItemFromCollection({collectionItemId: itemId})
      .subscribe(() => this.reload());

  }

  addToFavs() {
    this.collectionsService
      .collectionControllerAddCollectionToFav({collectionId: this.collection.id!})
      .subscribe(() => this.collection.favourite = true);
  }

  removeFromFavs() {
    this.collectionsService
      .collectionControllerRemoveCollectionFromFav({collectionId: this.collection.id!})
      .subscribe(() => this.collection.favourite = false);
  }

  private reload() {
    return this.itemService.itemsControllerGetItems({
      collectionId: this.collection.id!,
    }).subscribe((items) => (this.items = items));
  }
}
