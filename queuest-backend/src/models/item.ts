import {IsBoolean, IsEnum, IsNumber, IsOptional, IsString} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { CollectionItemType } from '../persistence/entities/collection-item.entity';

export class Item {
    @IsNumber()
    @ApiProperty({ required: false })
    @IsOptional()
    id: number;

    @IsString()
    @ApiProperty({ required: true })
    name: string;

    @IsBoolean()
    @ApiProperty({ required: false })
    calibrated: boolean | undefined;

    @IsEnum(CollectionItemType)
    @ApiProperty({ required: false })
    @IsOptional()
    type: CollectionItemType;
}
