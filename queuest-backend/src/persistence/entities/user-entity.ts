import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity({ name: 'user_tbl' })
export class UserEntity {
    @PrimaryColumn()
    id: number;

    @Column()
    uid: string;

    @Column()
    email: string;
}
