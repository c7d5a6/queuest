import {Component, OnInit} from '@angular/core';
import {BreakPoints, BreakpointsService} from "../../../services/breakpoints.service";

@Component({
  selector: 'app-collections',
  templateUrl: './collections.component.html',
  styleUrls: ['./collections.component.scss']
})
export class CollectionsComponent implements OnInit {

  showFavourite: boolean = false;

  constructor(private breakpointsService: BreakpointsService) {
  }

  ngOnInit(): void {
    this.breakpointsService.observe().subscribe(value => {
      switch (value){
        case BreakPoints.xs: this.showFavourite = true; break;
        case BreakPoints.sm: this.showFavourite = true; break;
        case BreakPoints.md: this.showFavourite = false; break;
        case BreakPoints.lg: this.showFavourite = false; break;
        case BreakPoints.xl: this.showFavourite = false; break;
        default:  this.showFavourite = false;
      }
    });
  }

}
