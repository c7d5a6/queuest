import { Component, Input } from '@angular/core';
import { Item } from '../../api/models/item';

@Component({
    selector: 'app-list',
    templateUrl: './list.component.html',
    styleUrls: ['./list.component.scss'],
})
export class ListComponent {
    @Input() items!: Item[];
}
