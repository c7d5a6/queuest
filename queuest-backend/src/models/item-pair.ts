import { ItemEntity } from '../persistence/entities/item.entity';
import { ItemRelation } from './item-relation';
import { ApiProperty } from '@nestjs/swagger';
import { Item } from './item';

export class ItemPair {
    @ApiProperty()
    item1: Item;

    @ApiProperty()
    item2: Item;

    @ApiProperty({ required: false })
    relation?: ItemRelation;

    constructor(item1: Item, item2: Item, relation?: ItemRelation) {
        this.item1 = item1;
        this.item2 = item2;
        this.relation = relation;
    }
}
