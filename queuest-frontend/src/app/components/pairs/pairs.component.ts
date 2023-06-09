import {Component, EventEmitter, Output} from '@angular/core';
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
    this.itemsService.itemsControllerGetBestPairs({size: 5}).subscribe(value => this.items = value);
  }

  itemPressed() {
    this.changes.emit();
  }
}
