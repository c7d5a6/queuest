import {BadRequestException, Injectable, Logger} from '@nestjs/common';
import {InjectRepository} from '@nestjs/typeorm';
import {UserEntity} from '../persistence/entities/user.entity';
import {Repository} from 'typeorm';
import {CollectionEntity} from '../persistence/entities/collection.entity';
import {AccessDeniedError} from 'sequelize';
import {Collection} from '../models/collection';

@Injectable()
export class CollectionService {
    private readonly logger = new Logger(CollectionService.name);

    constructor(
        @InjectRepository(UserEntity)
        private userRepository: Repository<UserEntity>,
        @InjectRepository(CollectionEntity)
        private collectionRepository: Repository<CollectionEntity>,
    ) {
    }

    private static mapToCollection(ce: CollectionEntity): Collection {
        return {name: ce.name, id: ce.id};
    }

    private static checkUserAccess(
        collection: CollectionEntity | null,
        userUid: string,
    ) {
        if (collection?.user.uid && collection?.user.uid !== userUid) {
            const error = new Error(
                `User ${userUid} can't access collection ${collection.id}`,
            );
            throw new AccessDeniedError(error);
        }
    }

    async getCurrentUserCollections(userUid: string): Promise<Collection[]> {
        const user = await this.userRepository.findOneBy({uid: userUid});
        if (!user) {
            const error = new Error(`There is no user with ${userUid}`);
            throw new AccessDeniedError(error);
        }
        const collections = await this.collectionRepository.findBy({
            user: {id: user.id},
        });
        return collections.map(CollectionService.mapToCollection);
    }

    public async getCollection(
        userUid: string,
        collectionId: number,
    ): Promise<CollectionEntity> {
        const user = await this.userRepository.findOneBy({uid: userUid});
        if (!user) {
            const error = new Error(`There is no user with ${userUid}`);
            throw new AccessDeniedError(error);
        }
        const collection = await this.collectionRepository.findOneBy({
            id: collectionId,
        });
        CollectionService.checkUserAccess(collection, userUid);
        if (collection == null) {
            const error = new Error(`There is no collection ${collectionId}`);
            throw new BadRequestException(error);
        }
        return collection;
    }

    async addCollection(
        userUid: string,
        collection: Collection,
    ): Promise<Collection> {
        if (collection.id != null) {
            const error = new Error(`Can't create collection with existing ID`);
            throw new BadRequestException(error);
        }
        const user = await this.getUser(userUid);
        const collectionEntity: CollectionEntity = new CollectionEntity();
        collectionEntity.user = user;
        collectionEntity.name = collection.name;
        const result = await this.collectionRepository.save(collectionEntity);
        return CollectionService.mapToCollection(result);
    }

    public async getUserCollection(userUid: string,
                                   collectionId: number,
    ): Promise<Collection> {
        let collectionEntity = await this.getCollection(userUid, collectionId);
        return CollectionService.mapToCollection(collectionEntity);
    }

    private async getUser(userUid: string) {
        const user = await this.userRepository.findOneBy({uid: userUid});
        if (!user) {
            const error = new Error(`There is no user with ${userUid}`);
            throw new AccessDeniedError(error);
        }
        return user;
    }
}
