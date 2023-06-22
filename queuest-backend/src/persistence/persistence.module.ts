import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user';

@Module({
    imports: [
        TypeOrmModule.forRoot({
            type: 'postgres',
            host: 'localhost',
            port: 5432,
            username: 'queuest',
            password: 'queuest',
            database: 'queuest',
            entities: [User],
            synchronize: false,
        }),
    ],
})
export class PersistenceModule {}
