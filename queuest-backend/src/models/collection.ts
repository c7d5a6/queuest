import {IsBoolean, IsNumber, IsOptional, IsString} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class Collection {
    @IsNumber()
    @ApiProperty({ required: false })
    @IsOptional()
    id: number;

    @IsString()
    @ApiProperty({ required: true })
    name: string;

    @IsBoolean()
    @ApiProperty({ required: false })
    favourite: boolean;
}
