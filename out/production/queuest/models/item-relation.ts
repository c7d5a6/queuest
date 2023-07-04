import { ApiProperty } from '@nestjs/swagger';
import { IsNumber } from 'class-validator';

export class ItemRelation {
    @ApiProperty({ required: true })
    @IsNumber()
    from: number;
    @ApiProperty({ required: true })
    @IsNumber()
    to: number;

    constructor(from: number, to: number) {
        this.from = from;
        this.to = to;
    }
}
