import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const typeOrmConfig: TypeOrmModuleOptions = {
    type: 'postgres',
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432', 10),
    username: 'queuest',
    password: process.env.DATABASE_PASSWORD || 'queuest',
    database: 'queuest',
    entities: [__dirname + '/entities/*.entity{.ts,.js}'],
    logging: process.env.DEV_DATABASE,
    synchronize: false,
    ssl: !process.env.DEV_DATABASE,
    extra: !process.env.DEV_DATABASE
        ? {
              ssl: {
                  rejectUnauthorized: false,
              },
          }
        : {},
};

module.exports = typeOrmConfig;
