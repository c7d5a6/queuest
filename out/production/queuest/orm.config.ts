import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { UserEntity } from './persistence/entities/user-entity';
import { CollectionEntity } from './persistence/entities/collection-entity';

export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: 'localhost',
    port: 5432,
    username: 'queuest',
    password: 'queuest',
    database: 'queuest',
    entities: [UserEntity, CollectionEntity],
    synchronize: false,
};

module.exports = typeOrmConfig;
