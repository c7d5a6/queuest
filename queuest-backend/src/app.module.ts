import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GraphService } from './services/graph.service';
import { ItemsService } from './services/items.service';
import { ItemsController } from './controllers/items.controller';
import { FirebaseService } from './auth/firebase.service';
import { UserService } from './services/user.service';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as typeOrmConfig from './orm.config';
import { PersistenceModule } from './persistence/persistence.module';

@Module({
    imports: [
        TypeOrmModule.forRoot(typeOrmConfig as TypeOrmModuleOptions),
        PersistenceModule,
    ],
    controllers: [AppController, ItemsController],
    providers: [
        AppService,
        GraphService,
        ItemsService,
        FirebaseService,
        UserService,
    ],
})
export class AppModule {}
