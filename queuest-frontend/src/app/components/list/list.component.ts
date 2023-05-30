import {Component, Input} from '@angular/core';
import {ItemEntity} from "../../api/models/item-entity";

@Component({
  selector: 'app-list',
  templateUrl: './list.component.html',
  styleUrls: ['./list.component.scss']
})
export class ListComponent {
  @Input() items!: ItemEntity[];
}
