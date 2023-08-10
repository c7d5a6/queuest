import {Component, OnInit} from '@angular/core';
import {BreakPoints, BreakpointsService} from "../../../services/breakpoints.service";
import {CollectionsService} from "../../../api/services/collections.service";
import {Collection} from "../../../api/models/collection";
import {DialogService} from "@ngneat/dialog";
import {AddCollectionComponent} from "../../add-collection/add-collection.component";

@Component({
  selector: 'app-collections',
  templateUrl: './collections.component.html',
  styleUrls: ['./collections.component.scss']
})
export class CollectionsComponent implements OnInit {

  collections: Collection[] = [];
  favCollections: Collection[] = [];
  showFavourite: boolean = false;

  constructor(private breakpointsService: BreakpointsService,
              private collectionsService: CollectionsService,
              private dialogService: DialogService) {
  }

  ngOnInit(): void {
    this.breakpointsService.observe().subscribe(value => {
      switch (value) {
        case BreakPoints.xs:
          this.showFavourite = true;
          break;
        case BreakPoints.sm:
          this.showFavourite = true;
          break;
        case BreakPoints.md:
          this.showFavourite = false;
          break;
        case BreakPoints.lg:
          this.showFavourite = false;
          break;
        case BreakPoints.xl:
          this.showFavourite = false;
          break;
        default:
          this.showFavourite = false;
      }
    });
    this.getCollections();
  }

  add(): void {
    this.dialogService.open(AddCollectionComponent, {
      // data is typed based on the passed generic
      data: {
        title: 'Add collection',
      },
    }).afterClosed$.subscribe(() => this.getCollections());
  }

  private getCollections() {
    this.collectionsService.collectionControllerGetCurrentUserCollections().subscribe(collections => {
      this.collections = collections;
    })
  }

}
