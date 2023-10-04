import {IsArray, IsBoolean, IsNumber, IsOptional, IsString} from 'class-validator';
import {ApiProperty} from '@nestjs/swagger';
import {Item} from "./item";

export class CollectionWithItems {
    @IsNumber()
    @ApiProperty({required: false})
    @IsOptional()
    id: number;

    @IsArray()
    @ApiProperty({isArray: true, type: Item})
    items: Item[];

    @IsNumber()
    @ApiProperty({required: false})
    calibrated: number;
}
