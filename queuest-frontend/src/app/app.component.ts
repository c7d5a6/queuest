import {Component, inject, OnInit} from '@angular/core';
import {ItemsService} from './api/services/items.service';
import {Auth} from '@angular/fire/auth';
import {Item} from "./api/models/item";
import {BreakpointObserver, Breakpoints, MediaMatcher} from "@angular/cdk/layout";
import {BreakPoints, BreakpointsService} from "./services/breakpoints.service";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
  items: Item[] = [];
  lastItem?: Item;
  breakpont: string = 'none';
  private auth: Auth = inject(Auth);

  constructor(private itemsService: ItemsService, private breakpointsService: BreakpointsService) {
  }

  ngOnInit(): void {
    this.reloadItems();
    this.breakpointsService.observe().subscribe(value => {
      switch (value){
        case BreakPoints.xs: this.breakpont = 'XS'; break;
        case BreakPoints.sm: this.breakpont = 'SM'; break;
        case BreakPoints.md: this.breakpont = 'MD'; break;
        case BreakPoints.lg: this.breakpont = 'LG'; break;
        case BreakPoints.xl: this.breakpont = 'XL'; break;
        default:  this.breakpont = 'NONE'; break;
      }
    });
  }

  reloadItems() {
    this.getItems();
    this.getLastItem();
  }

  getItems() {
    // this.itemsService
    //     .itemsControllerGetItems()
    //     .subscribe((value) => (this.items = value));
  }

  getLastItem() {
    // this.itemsService
    //     .itemsControllerGetLastItem()
    //     .subscribe((value) => (this.lastItem = value));
  }
}
