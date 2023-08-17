import { CreateDateColumn, PrimaryColumn, UpdateDateColumn } from 'typeorm';

export class BaseEntity {
    @PrimaryColumn({ generated: true })
    id: number;

    @CreateDateColumn({
        name: 'createdwhen',
        type: 'timestamp with time zone',
        default: () => 'CURRENT_TIMESTAMP(6)',
    })
    createdWhen: Date;

    @UpdateDateColumn({
        name: 'updatedwhen',
        type: 'timestamp with time zone',
        default: () => 'CURRENT_TIMESTAMP(6)',
        onUpdate: 'CURRENT_TIMESTAMP(6)',
    })
    updatedWhen: Date;
}
