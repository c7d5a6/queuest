import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString } from 'class-validator';

export class ItemEntity {
    @ApiProperty({ required: true })
    @IsNumber()
    id: number;

    @ApiProperty({ required: true })
    @IsString()
    name: string;

    constructor(id: number, name: string) {
        this.id = id;
        this.name = name;
    }
}
