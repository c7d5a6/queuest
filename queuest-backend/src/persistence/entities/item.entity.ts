import { BaseEntity } from './base.entity';
import { Column, Entity } from 'typeorm';

@Entity({ name: 'item_tbl' })
export class ItemEntity extends BaseEntity {
    @Column({ name: 'name' })
    name: string;
}
