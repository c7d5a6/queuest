import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from './entities/user-entity';
import { CollectionEntity } from './entities/collection-entity';

@Module({
    imports: [TypeOrmModule.forFeature([UserEntity, CollectionEntity])],
    exports: [TypeOrmModule],
})
export class PersistenceModule {}
