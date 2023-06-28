import { BaseEntity } from './base-entity';
import { Column, JoinColumn, ManyToOne } from 'typeorm';
import { CollectionEntity } from './collection-entity';

export enum CollectionItemType {
    ITEM = 'ITEM',
    COLLECTION = 'COLLECTION',
}

export class ItemEntity extends BaseEntity {
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
        lazy: true,
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
