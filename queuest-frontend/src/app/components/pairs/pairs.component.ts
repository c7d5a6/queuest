import {Component, EventEmitter, Output} from '@angular/core';
import {ItemEntity} from "../../api/models/item-entity";
import {ItemsService} from "../../api/services/items.service";
import {ItemPair} from "../../api/models/item-pair";

@Component({
  selector: 'app-pairs',
  templateUrl: './pairs.component.html',
  styleUrls: ['./pairs.component.scss']
})
export class PairsComponent {
  public items: ItemPair[] = [];
  @Output() changes = new EventEmitter<void>();

  constructor(private itemsService: ItemsService) {
  }

  ngOnInit(): void {
    this.getPairs();

  }

  getPairs() {
    this.itemsService.itemsControllerGetBestPairs({size: 5, exclude: []}).subscribe(value => this.items = value);
  }

  itemPressed(){
    this.changes.emit();
  }
}
