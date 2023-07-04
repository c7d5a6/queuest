import {
    Component,
    EventEmitter,
    Input,
    OnChanges,
    Output,
    SimpleChanges,
} from '@angular/core';
import { ItemsService } from '../../api/services/items.service';
import {Item} from "../../api/models/item";

@Component({
    selector: 'app-calibrate-item',
    templateUrl: './calibrate-item.component.html',
    styleUrls: ['./calibrate-item.component.scss'],
})
export class CalibrateItemComponent implements OnChanges {
    @Output() changes = new EventEmitter<void>();
    @Input() lastItem!: Item;
    // items: ItemPair[] = [];
    calibrated = false;
    changed = false;

    constructor(private itemsService: ItemsService) {}

    ngOnChanges(changes: SimpleChanges): void {
        if (
            changes['lastItem']?.currentValue?.id !==
            changes['lastItem']?.previousValue?.id
        ) {
            console.log(changes['lastItem']?.currentValue);
            this.reloadCalibration();
        }
    }

    getPairs() {
        this.getNextBestPair();
    }

    itemPressed(id: number) {
        this.changed = true;
        this.changes.emit();
        // if (id === this.items.length - 1) {
        //     this.getNextBestPair();
        // }
    }

    private reloadCalibration() {
        this.calibrated = false;
        this.changed = false;
        // this.items = [];
        this.getNextBestPair();
    }

    private getNextBestPair() {
        const ids = [];
        ids.push(this.lastItem.id);
        // this.items.forEach((item) => ids.push(item.item2.id));
        // this.itemsService
        //     .itemsControllerGetBestPair({
        //         id: this.lastItem.id,
        //         exclude: ids,
        //     })
        //     .subscribe((pair) => {
        //         if (!!pair) {
        //             this.changed = false;
        //             this.items.push(pair);
        //         } else {
        //             this.calibrated = true;
        //         }
        //     });
    }
}
