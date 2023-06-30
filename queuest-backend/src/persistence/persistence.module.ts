import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from './entities/user.entity';
import { CollectionEntity } from './entities/collection.entity';
import { CollectionItemEntity } from './entities/collection-item.entity';
import { ItemEntity } from './entities/item.entity';
import { ItemRepository } from './repositories/item.repository';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            UserEntity,
            CollectionEntity,
            CollectionItemEntity,
            ItemEntity,
        ]),
    ],
    exports: [TypeOrmModule, ItemRepository],
    providers: [ItemRepository],
})
export class PersistenceModule {}
