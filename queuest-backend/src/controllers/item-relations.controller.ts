import {Controller, Delete, Logger, Param, Post, Req, UseGuards} from '@nestjs/common';
import {ApiBearerAuth, ApiTags} from '@nestjs/swagger';
import {AuthGuard} from '../auth/auth.guard';
import {FirebaseUser} from '../auth/firebase-user';
import {ItemsRelationService} from "../services/items-relation.service";

@ApiTags('ItemsRelation')
@ApiBearerAuth()
@Controller('relations')
export class ItemRelationsController {
    private readonly logger = new Logger(ItemRelationsController.name);

    constructor(private readonly itemsRelationService: ItemsRelationService) {
    }

    @Post(':fromId/:toId')
    @UseGuards(AuthGuard)
    async addItem(@Req() request: any, @Param('fromId') fromId: number, @Param('toId') toId: number) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Adding relations from ${fromId} to ${toId}`);
        return await this.itemsRelationService.addRelationFromTo(user.uid, fromId, toId);
    }

    @Delete(':itemAId/:itemBId')
    @UseGuards(AuthGuard)
    async getItems(@Req() request: any, @Param('itemAId') itemAId: number, @Param('itemBId') itemBId: number) {
        const user: FirebaseUser = request.user;
        return await this.itemsRelationService.removeRelationBetween(user.uid, itemAId, itemBId);
    }

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
}
