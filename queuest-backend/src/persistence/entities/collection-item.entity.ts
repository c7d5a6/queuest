import { BaseEntity } from './base.entity';
import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { CollectionEntity } from './collection.entity';
import { ItemEntity } from './item.entity';

export enum CollectionItemType {
    ITEM = 'ITEM',
    COLLECTION = 'COLLECTION',
}

@Entity({ name: 'collection_item_tbl' })
export class CollectionItemEntity extends BaseEntity {
    @ManyToOne(() => CollectionEntity, {
        nullable: false,
        lazy: true,
    })
    @JoinColumn({ name: 'collection_id', referencedColumnName: 'id' })
    collection: CollectionEntity;

    @Column({
        type: 'enum',
        enum: CollectionItemType,
    })
    type: CollectionItemType;

    @ManyToOne(() => ItemEntity, {
        nullable: true,
        lazy: false,
        eager: true,
    })
    @JoinColumn({ name: 'item_id', referencedColumnName: 'id' })
    item?: ItemEntity;

    @ManyToOne(() => CollectionEntity, {
        nullable: true,
        lazy: true,
    })
    @JoinColumn({ name: 'collection_subitem_id', referencedColumnName: 'id' })
    collectionSubitem?: CollectionEntity;
}
