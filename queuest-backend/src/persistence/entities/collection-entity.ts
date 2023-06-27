import { Column, Entity, JoinColumn, JoinTable, ManyToOne } from 'typeorm';
import { BaseEntity } from './base-entity';
import { UserEntity } from './user-entity';

@Entity({ name: 'collection_tbl' })
export class CollectionEntity extends BaseEntity {
    @ManyToOne(() => UserEntity, { nullable: false, lazy: true })
    @JoinColumn({ name: 'user_id' })
    user: UserEntity;

    @Column()
    name: string;
}
