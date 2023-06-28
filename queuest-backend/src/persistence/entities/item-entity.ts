import { BaseEntity } from './base-entity';
import { Column } from 'typeorm';

export class ItemEntity extends BaseEntity {
    @Column({ name: 'name' })
    name: string;
}
