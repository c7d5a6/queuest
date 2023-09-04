import { BaseEntity } from './base.entity';
import { Entity, JoinColumn, ManyToOne } from 'typeorm';
import { CollectionItemEntity } from './collection-item.entity';

@Entity({ name: 'item_relation_tbl' })
export class ItemRelationEntity extends BaseEntity {
    @ManyToOne(() => CollectionItemEntity, {
        nullable: false,
        lazy: false,
        eager: true
    })
    @JoinColumn({ name: 'collection_item_from_id', referencedColumnName: 'id' })
    itemFrom: CollectionItemEntity;

    @ManyToOne(() => CollectionItemEntity, {
        nullable: false,
        lazy: false,
        eager: true
    })
    @JoinColumn({ name: 'collection_item_to_id', referencedColumnName: 'id' })
    itemTo: CollectionItemEntity;
}
