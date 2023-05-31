"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Items = void 0;
class Items {
    constructor() {
        this.items = new Map();
        this.size = () => this.items.size;
    }
    add(value) {
        this.items.set(value.id, value);
        return this;
    }
    clear() {
        this.items.clear();
    }
    delete(value) {
        return this.items.delete(value.id);
    }
    forEach(callbackfn, thisArg) {
        const newcallback = (value, key, set) => {
            const its = new Items();
            its.items = set;
            callbackfn(value, value, its);
        };
        this.items.forEach(newcallback, thisArg);
    }
    has(value) {
        return this.items.has(value.id);
    }
}
exports.Items = Items;
//# sourceMappingURL=items.js.map