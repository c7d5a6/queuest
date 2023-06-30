import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from './base.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'collection_tbl' })
export class CollectionEntity extends BaseEntity {
    @Column({ name: 'name' })
    name: string;

    @ManyToOne(() => UserEntity, {
        nullable: false,
        lazy: true,
    })
    @JoinColumn({ name: 'user_id', referencedColumnName: 'id' })
    user: UserEntity;
}
