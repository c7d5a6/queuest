import {Body, Controller, Delete, Get, Logger, Param, Post, Query, Req, UseGuards} from '@nestjs/common';
import {CollectionService} from '../services/collection.service';
import {ApiBearerAuth, ApiOkResponse, ApiQuery, ApiTags} from '@nestjs/swagger';
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
    @ApiQuery({name: 'nameFilter', type: String, required: false})
    @ApiOkResponse({
        description: 'User current user collections',
        type: [Collection],
    })
    @UseGuards(AuthGuard)
    async getCurrentUserCollections(@Req() request: any, @Query("nameFilter") nameFilter: string | undefined): Promise<Collection[]> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getCurrentUserCollections(user.uid, nameFilter, false);
    }

    @Get('fav')
    @ApiOkResponse({
        description: 'User current user collections',
        type: [Collection],
    })
    @UseGuards(AuthGuard)
    async getCurrentUserFavCollections(@Req() request: any): Promise<Collection[]> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getCurrentUserCollections(user.uid, undefined, true);
    }

    @Get(':collectionId')
    @ApiOkResponse({
        description: 'Get collection',
        type: Collection,
    })
    @UseGuards(AuthGuard)
    async getCollection(@Req() request: any, @Param('collectionId') collectionId: number): Promise<Collection> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getUserCollection(user.uid, collectionId);
    }

    @Get('fav')
    @ApiOkResponse({
        description: 'User current user favorite collections',
        type: [Collection],
    })
    @UseGuards(AuthGuard)
    async getCurrentUserFavoriteCollections(@Req() request: any): Promise<Collection[]> {
        const user: FirebaseUser = request.user;
        return await this.collectionService.getCurrentUserCollections(user.uid, undefined, true);
    }

    @Post()
    @UseGuards(AuthGuard)
    async addCollection(@Req() request: any, @Body() collection: Collection) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Add new collection ${JSON.stringify(collection)} for ${user.uid}`);
        await this.collectionService.addCollection(user.uid, collection);
    }

    @Post('fav/:collectionId')
    @UseGuards(AuthGuard)
    async addCollectionToFav(@Req() request: any, @Param('collectionId') collectionId: number) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Add collection ${collectionId} to Fav for ${user.uid}`);
        await this.collectionService.addCollectionToFav(user.uid, collectionId);
    }

    @Post('visit/:collectionId')
    @UseGuards(AuthGuard)
    async visitCollection(@Req() request: any, @Param('collectionId') collectionId: number) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Visit collection ${collectionId} for ${user.uid}`);
        await this.collectionService.visitCollection(user.uid, collectionId);
    }

    @Delete('fav/:collectionId')
    @UseGuards(AuthGuard)
    async removeCollectionFromFav(@Req() request: any, @Param('collectionId') collectionId: number) {
        const user: FirebaseUser = request.user;
        this.logger.log(`Remove collection ${collectionId} from Fav for ${user.uid}`);
        await this.collectionService.removeCollectionFromFav(user.uid, collectionId);
    }
}
