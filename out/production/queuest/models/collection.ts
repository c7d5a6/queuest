import { IsNumber, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class Collection {
    @IsNumber()
    @ApiProperty({ required: false })
    id: number;

    @IsString()
    @ApiProperty({ required: true })
    name: string;
}
