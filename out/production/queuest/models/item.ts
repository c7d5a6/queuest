import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class Item {
    @IsString()
    @ApiProperty({ required: true })
    name: string;
}
