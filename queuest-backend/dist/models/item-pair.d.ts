import { ItemEntity } from '../persistence/entities/item.entity';
import { ItemRelation } from './item-relation';
export declare class ItemPair {
    item1: ItemEntity;
    item2: ItemEntity;
    relation?: ItemRelation;
    constructor(item1: ItemEntity, item2: ItemEntity, relation?: ItemRelation);
}
