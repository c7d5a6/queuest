import {Body, Controller, Get, Logger, Param, Post, Req, UseGuards,} from '@nestjs/common';
import {CollectionService} from '../services/collection.service';
import {ApiBearerAuth, ApiOkResponse, ApiTags} from '@nestjs/swagger';
import {AuthGuard} from '../auth/auth.guard';
import {FirebaseUser} from '../auth/firebase-user';
import {Collection} from '../models/collection';

@ApiTags('Collections')
@ApiBearerAuth()
@Controller('collections')
export class CollectionController {
    private readonly logger = new Logger(CollectionController.name);

    constructor(private readonly collectionService: CollectionService) {
    }

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

    @Get(':collectionId')
    @ApiOkResponse({
        description: 'Get collection',
        type: Collection,
    })
    @UseGuards(AuthGuard)
    async getCollection(
        @Req() request: any,
        @Param('collectionId') collectionId: number,
    ): Promise<Collection> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getUserCollection(user.uid, collectionId);
    }

    @Get('fav')
    @ApiOkResponse({
        description: 'User current user favorite collections',
        type: [Collection],
    })
    @UseGuards(AuthGuard)
    async getCurrentUserFavoriteCollections(
        @Req() request: any,
    ): Promise<Collection[]> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getCurrentUserCollections(user.uid);
    }

    @Post()
    @UseGuards(AuthGuard)
    async addCollection(@Req() request: any, @Body() collection: Collection) {
        const user: FirebaseUser = request.user;
        this.logger.log(
            `Add new collection ${JSON.stringify(collection)} for ${user.uid}`,
        );
        await this.collectionService.addCollection(user.uid, collection);
    }
}
