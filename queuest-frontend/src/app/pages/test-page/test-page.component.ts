import {Component} from '@angular/core';

@Component({
  selector: 'app-test-page',
  templateUrl: './test-page.component.html',
  styleUrls: ['./test-page.component.scss']
})
export class TestPageComponent {
  idx: number = 0;

  select(number: number) {
    this.idx = number;
  }
}
