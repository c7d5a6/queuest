import {Component, EventEmitter, Input, Output} from '@angular/core';
import {ItemPair} from "../../../api/models/item-pair";
import {ItemsRelationService} from "../../../api/services/items-relation.service";

@Component({
  selector: 'app-pair',
  templateUrl: './pair.component.html',
  styleUrls: ['./pair.component.scss'],
})
export class PairComponent {
  @Input() pair!: ItemPair;
  @Output() pressed = new EventEmitter<void>();

  constructor(private itemsRelationService: ItemsRelationService) {
  }

  addRelation(from: number | undefined, to: number | undefined) {
    if (from !== undefined && to !== undefined) {
      console.log('adding relation');
      const relation = {
        from: from,
        to: to,
      };
      this.itemsRelationService
        .itemRelationsControllerAddItem({
          fromId: from,
          toId: to
        })
        .subscribe(() => {
          this.pair.relation = relation;
          this.pressed.emit();
        });
    }
  }

  deleteRelation(from: number, to: number) {
    console.log('deleting relation');
    this.itemsRelationService
      .itemRelationsControllerGetItems({
        itemAId: from,
        itemBId: to
      })
      .subscribe(() => {
        this.pair.relation = undefined;
        this.pressed.emit();
      });
  }
}
