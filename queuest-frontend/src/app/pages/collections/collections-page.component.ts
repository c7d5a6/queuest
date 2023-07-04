import {Component, OnInit} from '@angular/core';
import {BreakPoints, BreakpointsService} from "../../services/breakpoints.service";

@Component({
  selector: 'app-collections-page',
  templateUrl: './collections-page.component.html',
  styleUrls: ['./collections-page.component.scss']
})
export class CollectionsPageComponent implements OnInit {
  showSidePanel: boolean;
  sidePanelColumns: number;
  collectionsPanelColumns: number;

  constructor(private breakpointsService: BreakpointsService) {
  }

  ngOnInit(): void {
    this.breakpointsService.observe().subscribe(value => {
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

  }
}
