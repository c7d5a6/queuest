import { Injectable } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { ItemEntity } from '../entities/item.entity';
import { ItemRelationEntity } from '../entities/item-relation.entity';

@Injectable() // here
export class ItemRelationRepository extends Repository<ItemRelationEntity> {
    constructor(private dataSource: DataSource) {
        super(ItemRelationEntity, dataSource.createEntityManager());
    }
}
