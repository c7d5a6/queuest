import { Component, EventEmitter, Input, Output } from '@angular/core';
import { ItemPair } from '../../../api/models/item-pair';
import { ItemsService } from '../../../api/services/items.service';

@Component({
    selector: 'app-pair',
    templateUrl: './pair.component.html',
    styleUrls: ['./pair.component.scss'],
})
export class PairComponent {
    @Input() pair!: ItemPair;
    @Output() pressed = new EventEmitter<void>();

    constructor(private itemsService: ItemsService) {}

    addRelation(from: number | undefined, to: number | undefined) {
        if (from !== undefined && to !== undefined) {
            console.log('adding relation');
            const relation = {
                from: from,
                to: to,
            };
            this.itemsService
                .itemsControllerAddRelation({
                    body: relation,
                })
                .subscribe(() => {
                    this.pair.relation = relation;
                    this.pressed.emit();
                });
        }
    }

    deleteRelation(from: number, to: number) {
        console.log('deleting relation');
        const relation = {
            from: from,
            to: to,
        };
        this.itemsService
            .itemsControllerDeleteRelation({
                body: relation,
            })
            .subscribe(() => {
                this.pair.relation = undefined;
                this.pressed.emit();
            });
    }
}
