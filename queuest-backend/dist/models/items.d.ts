import { Item } from './item';
export declare class Items {
    items: Map<number, Item>;
    readonly size: () => number;
    add(value: Item): this;
    clear(): void;
    delete(value: Item): boolean;
    forEach(callbackfn: (value: Item, value2: Item, set: Items) => void, thisArg?: any): void;
    has(value: Item): boolean;
}
