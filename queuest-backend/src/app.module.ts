import { Module } from '@nestjs/common';
import { AppService } from './app.service';
import { GraphService } from './services/graph.service';
import { ItemsService } from './services/items.service';
import { ItemsController } from './controllers/items.controller';
import { FirebaseService } from './auth/firebase.service';
import { UserService } from './services/user.service';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as typeOrmConfig from './persistence/orm.config';
import { PersistenceModule } from './persistence/persistence.module';
import { CollectionController } from './controllers/collection.controller';
import { CollectionService } from './services/collection.service';
import { ItemsRelationService } from './services/items-relation.service';
import {ItemRelationsController} from "./controllers/item-relations.controller";

@Module({
    imports: [TypeOrmModule.forRoot(typeOrmConfig as TypeOrmModuleOptions), PersistenceModule],
    controllers: [ItemsController, CollectionController, ItemRelationsController],
    providers: [
        AppService,
        GraphService,
        ItemsService,
        ItemsRelationService,
        FirebaseService,
        UserService,
        CollectionService,
    ],
})
export class AppModule {}
