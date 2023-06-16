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
import { Item } from '../models/item';

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
    @ApiQuery({ name: 'size', type: Number, required: true })
    @ApiOkResponse({
        description: 'Get best pairs to compare',
        type: [ItemPair],
    })
    getBestPairs(@Query('size') size: number): ItemPair[] {
        return this.itemsService.getBestPairs(size);
    }

    @Get('last')
    @ApiOkResponse({
        description: 'Get last item',
        type: ItemEntity,
    })
    getLastItem(): ItemEntity | undefined {
        return this.itemsService.getLastItem();
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
    addItem(@Body() item: Item) {
        console.log(JSON.stringify(item));
        this.itemsService.addItem(item);
    }

    @Post('relation')
    addRelation(@Body() relation: ItemRelation) {
        console.log(JSON.stringify(relation));
        this.itemsService.addRelation(relation);
    }

    @Delete('relation')
    deleteRelation(@Body() relation: ItemRelation) {
        console.log(JSON.stringify(relation));
        this.itemsService.deleteRelation(relation);
    }
}
