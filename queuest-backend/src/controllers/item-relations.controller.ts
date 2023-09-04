import { Body, Controller, Delete, Logger, Param, Post, Req, UseGuards } from '@nestjs/common';
import { ItemsService } from '../services/items.service';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Item } from '../models/item';
import { AuthGuard } from '../auth/auth.guard';
import { FirebaseUser } from '../auth/firebase-user';
import {ItemsRelationService} from "../services/items-relation.service";

@ApiTags('ItemsRelation')
@ApiBearerAuth()
@Controller('relations')
export class ItemRelationsController {
    private readonly logger = new Logger(ItemRelationsController.name);

    constructor(private readonly itemsRelationService: ItemsRelationService) {}

    @Post(':fromId/:toId')
    @UseGuards(AuthGuard)
    async addItem(@Req() request: any, @Param('fromId') fromId: number, @Param('toId') toId: number) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Adding relations from ${fromId} to ${toId}`);
        return await this.itemsRelationService.addRelationFromTo(user.uid,fromId,toId);
    }

    @Delete(':fromId/:toId')
    @UseGuards(AuthGuard)
    async getItems(@Req() request: any, @Param('fromId') fromId: number, @Param('toId') toId: number) {
        const user: FirebaseUser = request.user;
        return await this.itemsRelationService.removeRelationFromTo(user.uid,fromId,toId);
    }
    //
    // @Get('pairs')
    // @ApiQuery({ name: 'size', type: Number, required: true })
    // @UseGuards(AuthGuard)
    // @ApiOkResponse({
    //     description: 'Get best pairs to compare',
    //     type: [ItemPair],
    // })
    // getBestPairs(
    //     @Param('collectionId') collectionId: number,
    //     @Query('size') size: number,
    // ): ItemPair[] {
    //     return this.itemsService.getBestPairs(size);
    // }
    //
    // // @Get('last')
    // // @UseGuards(AuthGuard)
    // // @ApiOkResponse({
    // //     description: 'Get last item',
    // //     type: Item,
    // // })
    // // getLastItem(@Param('collectionId') collectionId: number,): Item | undefined {
    // //     return this.itemsService.getLastItem();
    // // }
    //
    // @Get(':id/bestpair')
    // @ApiQuery({ name: 'exclude', type: [Number], required: false })
    // @UseGuards(AuthGuard)
    // @ApiOkResponse({
    //     description: 'Get best pair for item to compare',
    //     type: ItemPair,
    // })
    // getBestPair(
    //     @Param('id') itemId: number,
    //     @Query(
    //         'exclude',
    //         new ParseArrayPipe({
    //             optional: true,
    //             items: Number,
    //             separator: ',',
    //         }),
    //     )
    //     exclude: number[] | undefined,
    // ): ItemPair | undefined {
    //     return this.itemsService.getBestPair(itemId, exclude);
    // }
    //
    // @Post('relation')
    // @UseGuards(AuthGuard)
    // addRelation(@Body() relation: ItemRelation) {
    //     this.logger.log(JSON.stringify(relation));
    //     this.itemsService.addRelation(relation);
    // }
    //
    // @Delete('relation')
    // @UseGuards(AuthGuard)
    // deleteRelation(@Body() relation: ItemRelation) {
    //     this.logger.log(JSON.stringify(relation));
    //     this.itemsService.deleteRelation(relation);
    // }
}
