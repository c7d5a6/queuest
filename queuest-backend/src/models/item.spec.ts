import { Item } from './item';

describe('Item', () => {
    it('should be defined', () => {
        expect(new Item(1,"1", 1)).toBeDefined();
    });
});
