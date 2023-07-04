import {
    Body,
    Controller,
    Get,
    Logger,
    Post,
    Req,
    UseGuards,
} from '@nestjs/common';
import { CollectionService } from '../services/collection.service';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { ItemEntity } from '../persistence/entities/item.entity';
import { AuthGuard } from '../auth/auth.guard';
import { CollectionEntity } from '../persistence/entities/collection-entity';
import { FirebaseUser } from '../auth/firebase-user';
import { Item } from '../models/item';
import { Collection } from '../models/collection';

@ApiTags('Collections')
@ApiBearerAuth()
@Controller('collections')
export class CollectionController {
    private readonly logger = new Logger(CollectionController.name);

    constructor(private readonly collectionService: CollectionService) {}

    @Get()
    @ApiOkResponse({
        description: 'User current user collections',
        type: [Collection],
    })
    @UseGuards(AuthGuard)
    async getCurrentUserCollections(
        @Req() request: any,
    ): Promise<Collection[]> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getCurrentUserCollections(user.uid);
    }

    @Post()
    @UseGuards(AuthGuard)
    addItem(@Req() request: any, @Body() collection: Collection) {
        this.logger.log(JSON.stringify(item));
        this.itemsService.addItem(item);
    }

    // @Post()
    // @ApiOkResponse({
    //     description: 'User current user collections',
    //     type: [CollectionEntity],
    // })
    // @UseGuards(AuthGuard)
    // async getCurrentUserCollections(
    //     @Req() request: any,
    // ): Promise<CollectionEntity[]> {
    //     const user: FirebaseUser = request.user;
    //     return await this.collectionService.getCurrentUserCollections(user.uid);
    // }
}
