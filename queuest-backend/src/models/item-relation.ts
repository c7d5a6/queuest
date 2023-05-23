import { Item } from './item';

export class ItemRelation {
    itemFrom: Item;
    itemTo: Item;
    weight: number;

    getLabel(): string {
        return `${Math.min(this.itemFrom.id, this.itemTo.id)}:${Math.max(
            this.itemFrom.id,
            this.itemTo.id,
        )}`;
    }
}
