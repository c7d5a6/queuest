import { Items } from './items';
import { Item } from './item';

describe('Items', () => {
    it('should be defined', () => {
        expect(new Items()).toBeDefined();
    });

    it('get size of new epmty', () => {
        expect(new Items().size()).toBe(0);
    });

    it('get size after item added', () => {
        const items = new Items();
        const item = new Item(1, '1', 0);
        items.add(item);
        expect(items.size()).toBe(1);
    });
});
