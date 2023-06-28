import {
    Body,
    Controller,
    Delete,
    Get,
    Logger,
    Param,
    ParseArrayPipe,
    Post,
    Query,
    UseGuards,
} from '@nestjs/common';
import { ItemsService } from '../services/items.service';
import { ItemEntity } from '../persistence/entities/item-entity';
import { ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import { Item } from '../models/item';
import { AuthGuard } from '../auth/auth.guard';

@ApiTags('Items')
@Controller('items')
export class ItemsController {
    private readonly logger = new Logger(ItemsController.name);
    constructor(private readonly itemsService: ItemsService) {}

    @Get()
    @ApiOkResponse({ description: 'Sorted items', type: [ItemEntity] })
    @UseGuards(AuthGuard)
    getItems(): ItemEntity[] {
        const result = this.itemsService.getItemsSorted();
        return result;
    }

    @Get('pairs')
    @ApiQuery({ name: 'size', type: Number, required: true })
    @UseGuards(AuthGuard)
    @ApiOkResponse({
        description: 'Get best pairs to compare',
        type: [ItemPair],
    })
    getBestPairs(@Query('size') size: number): ItemPair[] {
        return this.itemsService.getBestPairs(size);
    }

    @Get('last')
    @UseGuards(AuthGuard)
    @ApiOkResponse({
        description: 'Get last item',
        type: ItemEntity,
    })
    getLastItem(): ItemEntity | undefined {
        return this.itemsService.getLastItem();
    }

    @Get(':id/bestpair')
    @ApiQuery({ name: 'exclude', type: [Number], required: false })
    @UseGuards(AuthGuard)
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
    @UseGuards(AuthGuard)
    addItem(@Body() item: Item) {
        this.logger.log(JSON.stringify(item));
        this.itemsService.addItem(item);
    }

    @Post('relation')
    @UseGuards(AuthGuard)
    addRelation(@Body() relation: ItemRelation) {
        this.logger.log(JSON.stringify(relation));
        this.itemsService.addRelation(relation);
    }

    @Delete('relation')
    @UseGuards(AuthGuard)
    deleteRelation(@Body() relation: ItemRelation) {
        this.logger.log(JSON.stringify(relation));
        this.itemsService.deleteRelation(relation);
    }
}
