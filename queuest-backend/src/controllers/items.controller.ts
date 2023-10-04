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
    Req,
    UseGuards
} from '@nestjs/common';
import {ItemsService} from '../services/items.service';
import {ApiBearerAuth, ApiOkResponse, ApiQuery, ApiTags} from '@nestjs/swagger';
import {Item} from '../models/item';
import {AuthGuard} from '../auth/auth.guard';
import {FirebaseUser} from '../auth/firebase-user';
import {ItemPair} from "../models/item-pair";
import {CollectionWithItems} from "../models/collection-with-items";

@ApiTags('Items')
@ApiBearerAuth()
@Controller('collections/:collectionId/items')
export class ItemsController {
    private readonly logger = new Logger(ItemsController.name);

    constructor(private readonly itemsService: ItemsService) {
    }

    @Post()
    @UseGuards(AuthGuard)
    @ApiOkResponse({
        description: 'Add new item to collection',
        type: Number,
    })
    async addItem(@Req() request: any, @Param('collectionId') collectionId: number, @Body() item: Item): Promise<Number> {
        const user: FirebaseUser = request.user;
        this.logger.log(JSON.stringify(item));
        return await this.itemsService.addItem(user.uid, collectionId, item);
    }

    @Delete(':collectionItemId')
    @UseGuards(AuthGuard)
    @ApiOkResponse({
        description: 'Deleteitem from collection',
    })
    async deleteItemFromCollection(@Req() request: any, @Param('collectionItemId') collectionItemId: number): Promise<void> {
        const user: FirebaseUser = request.user;
        this.logger.log('Delete item {}', collectionItemId);
        return await this.itemsService.deleteItem(user.uid, collectionItemId);
    }

    @Get()
    @ApiOkResponse({description: 'Sorted items', type: CollectionWithItems})
    @UseGuards(AuthGuard)
    async getItems(@Req() request: any, @Param('collectionId') collectionId: number): Promise<CollectionWithItems> {
        const user: FirebaseUser = request.user;
        return await this.itemsService.getItemsSorted(user.uid, collectionId);
    }

    @Get(':id/bestpair')
    @ApiQuery({name: 'exclude', type: [Number], required: false})
    @UseGuards(AuthGuard)
    @ApiOkResponse({
        description: 'Get best pair for item to compare',
        type: ItemPair,
    })
    async getBestPair(
        @Req() request: any,
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
    ): Promise<ItemPair | undefined> {
        const user: FirebaseUser = request.user;
        return await this.itemsService.getBestPair(user.uid, itemId, exclude);
    }
}
