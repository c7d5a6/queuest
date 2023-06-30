import { IsNumber, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class Item {
    @IsNumber()
    @ApiProperty({ required: false })
    @IsOptional()
    id: number;

    @IsString()
    @ApiProperty({ required: true })
    name: string;
}
