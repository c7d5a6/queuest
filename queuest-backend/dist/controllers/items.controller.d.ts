import { ItemsService } from '../services/items.service';
import { ItemEntity } from '../persistence/entities/item.entity';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import { ItemPairFilter } from './filter/item-pair-filter';
export declare class ItemsController {
    private readonly itemsService;
    constructor(itemsService: ItemsService);
    getItems(): ItemEntity[];
    getBestPairs(exclude: ItemPairFilter): ItemPair[];
    addItem(item: ItemEntity): void;
    addRelation(relation: ItemRelation): void;
    deleteRelation(relation: ItemRelation): void;
}
