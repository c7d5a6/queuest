import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432', 10),
    username: 'queuest',
    password:  process.env.DATABASE_PASSWORD || 'queuest',
    database: 'queuest',
    entities: [__dirname + '/entities/*.entity{.ts,.js}'],
    synchronize: false,
    ssl:true
};

module.exports = typeOrmConfig;
