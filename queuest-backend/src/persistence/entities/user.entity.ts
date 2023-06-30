import { Column, Entity } from 'typeorm';
import { BaseEntity } from './base.entity';

@Entity({ name: 'user_tbl' })
export class UserEntity extends BaseEntity {
    @Column()
    uid: string;

    @Column()
    email: string;
}
