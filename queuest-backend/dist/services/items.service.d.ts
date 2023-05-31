import { ItemEntity } from '../persistence/entities/item.entity';
import { GraphService } from './graph.service';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import { ItemPairFilter } from '../controllers/filter/item-pair-filter';
export declare class ItemsService {
    private readonly graphService;
    items: ItemEntity[];
    relations: Map<number, number[]>;
    constructor(graphService: GraphService);
    getItemsSorted(): ItemEntity[];
    addItem(item: ItemEntity): void;
    addRelation(relation: ItemRelation): void;
    deleteRelation(relation: ItemRelation): void;
    getBestPairs(filter: ItemPairFilter): ItemPair[];
    private removeRelationFromTo;
    private getEdges;
}
