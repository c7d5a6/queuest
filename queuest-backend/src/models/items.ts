import { Item } from './item';

export class Items {
    items: Map<number, Item> = new Map<number, Item>();

    readonly size = () => this.items.size;

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
        ) => {
            const its = new Items();
            its.items = set;
            callbackfn(value, value, its);
        };
        this.items.forEach(newcallback, thisArg);
    }

    has(value: Item): boolean {
        return this.items.has(value.id);
    }
}
