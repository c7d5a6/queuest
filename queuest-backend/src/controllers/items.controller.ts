import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    ParseArrayPipe,
    Post,
    Query,
} from '@nestjs/common';
import { ItemsService } from '../services/items.service';
import { ItemEntity } from '../persistence/entities/item.entity';
import { ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import { ItemPairFilter } from './filter/item-pair-filter';
import { BestItemPairFilter } from './filter/best-item-pair-filter';

@ApiTags('Items')
@Controller('items')
export class ItemsController {
    constructor(private readonly itemsService: ItemsService) {}

    @Get()
    @ApiOkResponse({ description: 'Sorted items', type: [ItemEntity] })
    getItems(): ItemEntity[] {
        const result = this.itemsService.getItemsSorted();
        return result;
    }

    @Get('pairs')
    @ApiOkResponse({
        description: 'Get best pairs to compare',
        type: [ItemPair],
    })
    getBestPairs(@Query() exclude: ItemPairFilter): ItemPair[] {
        return this.itemsService.getBestPairs(exclude);
    }

    @Get(':id/bestpair')
    @ApiQuery({ name: 'exclude', type: [Number], required: false })
    @ApiOkResponse({
        description: 'Get best pair for item to compare',
        type: ItemPair,
    })
    getBestPair(
        @Param('id') itemId: number,
        @Query(
            'exclude',
            new ParseArrayPipe({
                optional: true,
                items: Number,
                separator: ',',
            }),
        )
        exclude: number[] | undefined,
    ): ItemPair | undefined {
        return this.itemsService.getBestPair(itemId, exclude);
    }

    @Post()
    addItem(@Body() item: ItemEntity) {
        this.itemsService.addItem(item);
    }

    @Post('relation')
    addRelation(@Body() relation: ItemRelation) {
        this.itemsService.addRelation(relation);
    }

    @Delete('relation')
    deleteRelation(@Body() relation: ItemRelation) {
        this.itemsService.deleteRelation(relation);
    }
}
