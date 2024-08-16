import { Component, Input, OnInit } from '@angular/core';
import {
  BreakPoints,
  BreakpointsService,
} from '../../../services/breakpoints.service';
import { CollectionsService } from '../../../api/services/collections.service';
import { Collection } from '../../../api/models/collection';
import { DialogService } from '@ngneat/dialog';
import { AddCollectionComponent } from '../../add-collection/add-collection.component';
import { Router } from '@angular/router';

@Component({
  selector: 'app-collections',
  templateUrl: './collections.component.html',
  styleUrls: ['./collections.component.scss'],
})
export class CollectionsComponent implements OnInit {
  @Input() collections!: Collection[];
  @Input() favCollections!: Collection[];
  showFavourite = false;

  constructor(
    private breakpointsService: BreakpointsService,
    private collectionsService: CollectionsService,
    private dialogService: DialogService,
    private router: Router,
  ) { }

  navigate(collectionId: number | undefined): void {
    this.router.navigate(['collection', collectionId]);
  }

  ngOnInit(): void {
    console.log('CollectionsComponent', this.collections);
    this.breakpointsService.observe().subscribe((value) => {
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
  }

  add(): void {
    this.dialogService
      .open(AddCollectionComponent, {
        // data is typed based on the passed generic
        data: {
          title: 'Add collection',
        },
      })
      .afterClosed$.subscribe(() => this.getCollections());
  }

  private getCollections() {
    this.collectionsService
      .collectionControllerGetCurrentUserCollections()
      .subscribe((collections) => {
        this.collections = collections;
      });
  }
}
