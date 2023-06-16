import { ItemPair } from '../../models/item-pair';
import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsNumber } from 'class-validator';
import { Transform } from 'class-transformer';

export class ItemPairFilter {
    // @ApiProperty({ required: false, type: [ItemPair] })
    // @IsArray()
    // exclude: ItemPair[];

    @ApiProperty({ type: Number, required: true })
    // @IsNumber({ allowInfinity: false, allowNaN: false })
    @Transform(({ value }) => Number(value))
    size: number;
}
