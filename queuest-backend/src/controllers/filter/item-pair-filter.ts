import { ItemPair } from '../../models/item-pair';
import { ApiProperty } from '@nestjs/swagger';

export class ItemPairFilter {

    @ApiProperty()
    exclude: ItemPair[];

    @ApiProperty()
    size: number;
}
