import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: 'localhost',
    port: 5432,
    username: 'queuest',
    password: 'queuest',
    database: 'queuest',
    entities: [__dirname + '/entities/*.entity{.ts,.js}'],
    synchronize: false,
};

module.exports = typeOrmConfig;
