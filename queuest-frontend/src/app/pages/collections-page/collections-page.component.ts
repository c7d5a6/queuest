import { Component, OnInit } from '@angular/core';
import {
    BreakPoints,
    BreakpointsService,
} from '../../services/breakpoints.service';
import { ActivatedRoute, Data } from '@angular/router';
import { Collection } from '../../api/models/collection';

@Component({
    selector: 'app-collections-page',
    templateUrl: './collections-page.component.html',
    styleUrls: ['./collections-page.component.scss'],
})
export class CollectionsPageComponent implements OnInit {
    collections: Array<Collection> = [];
    favCollections: Array<Collection> = [];
    showSidePanel = false;
    sidePanelColumns = 0;
    collectionsPanelColumns = 0;

    constructor(
        private breakpointsService: BreakpointsService,
        private activatedRoute: ActivatedRoute,
    ) {}

    ngOnInit(): void {
        console.log('CollectionsPageComponent');
        this.breakpointsService.observe().subscribe((value) => {
            this.showSidePanel = false;
            this.sidePanelColumns = 3;
            this.collectionsPanelColumns = 4;
            switch (value) {
                case BreakPoints.xs:
                    break;
                case BreakPoints.sm:
                    this.collectionsPanelColumns = 8;
                    break;
                case BreakPoints.md:
                    this.showSidePanel = true;
                    this.collectionsPanelColumns = 9;
                    break;
              case BreakPoints.lg:
                    this.showSidePanel = true;
                    this.collectionsPanelColumns = 9;
                    break;
              case BreakPoints.xl:
                    this.showSidePanel = true;
                    this.sidePanelColumns = 4;
                    this.collectionsPanelColumns = 8;
                    break;
                default:
                    break;
            }
        });
        this.activatedRoute.data.subscribe((routeData: Data) => {
            const data = routeData as { collections: Array<Collection>, favCollections: Array<Collection> };
            if (data) {
              if (data.collections) {
                this.collections = data.collections;
              }
              if (data.favCollections) {
                this.favCollections = data.favCollections;
              }
            }
        });
    }
}
