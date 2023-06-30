import { Injectable } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { ItemEntity } from '../entities/item.entity';

@Injectable() // here
export class ItemRepository extends Repository<ItemEntity> {
    constructor(private dataSource: DataSource) {
        super(ItemEntity, dataSource.createEntityManager());
    }
}
