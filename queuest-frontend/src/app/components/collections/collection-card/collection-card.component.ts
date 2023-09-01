import { Component, Input } from '@angular/core';
import { Collection } from '../../../api/models/collection';

@Component({
    selector: 'app-collection-card',
    templateUrl: './collection-card.component.html',
    styleUrls: ['./collection-card.component.scss'],
})
export class CollectionCardComponent {
    @Input() collection!: Collection;
}
