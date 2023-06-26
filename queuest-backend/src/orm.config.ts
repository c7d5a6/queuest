import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { UserEntity } from './persistence/entities/user-entity';

export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: 'localhost',
    port: 5432,
    username: 'queuest',
    password: 'queuest',
    database: 'queuest',
    entities: [UserEntity],
    synchronize: false,
};

module.exports = typeOrmConfig;
