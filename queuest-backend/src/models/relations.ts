import { ItemRelation } from './item-relation';

export class Relations {
    relations: Map<string, ItemRelation>;
    readonly size = () => this.relations.size;

    constructor(items: Map<number, Item>) {
        this.items = items;
    }

    add(value: Item): this {
        this.items.set(value.id, value);
        return this;
    }

    clear(): void {
        this.items.clear();
    }

    delete(value: Item): boolean {
        return this.items.delete(value.id);
    }

    forEach(
        callbackfn: (value: Item, value2: Item, set: Items) => void,
        thisArg?: any,
    ): void {
        const newcallback = (
            value: Item,
            key: number,
            set: Map<number, Item>,
        ) => callbackfn(value, value, new Items(set));
        this.items.forEach(newcallback, thisArg);
    }

    has(value: Item): boolean {
        return this.items.has(value.id);
    }
}
