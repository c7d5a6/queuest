import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { UserEntity } from '../persistence/entities/user-entity';
import { Repository } from 'typeorm';
import { CollectionEntity } from '../persistence/entities/collection-entity';
import { AccessDeniedError } from 'sequelize';

@Injectable()
export class CollectionService {
    private readonly logger = new Logger(CollectionService.name);

    constructor(
        @InjectRepository(UserEntity)
        private userRepository: Repository<UserEntity>,
        @InjectRepository(CollectionEntity)
        private collectionRepository: Repository<CollectionEntity>,
    ) {}

    async getCurrentUserCollections(
        userUid: string,
    ): Promise<CollectionEntity[]> {
        const user = await this.userRepository.findOneBy({ uid: userUid });
        if (!user) {
            const error = new Error(`There is no user with ${userUid}`);
            throw new AccessDeniedError(error);
        }
        const collections = await this.collectionRepository.findBy({
            user: { id: user.id },
        });
        return collections;
    }

    async addCurrentUserCollection(
        userUid: string,
        collectionName: string,
    ): Promise<CollectionEntity> {
        const user = await this.userRepository.findOneBy({ uid: userUid });
        if (!user) {
            const error = new Error(`There is no user with ${userUid}`);
            throw new AccessDeniedError(error);
        }
        const collection: CollectionEntity = new CollectionEntity();
        collection.user = user;
        collection.name = collectionName;
        return await this.collectionRepository.save(collection);
    }
}
