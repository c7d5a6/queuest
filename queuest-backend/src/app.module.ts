import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GraphService } from './services/graph.service';
import { ItemsService } from './services/items.service';
import { ItemsController } from './controllers/items.controller';

@Module({
    imports: [],
    controllers: [AppController, ItemsController],
    providers: [AppService, GraphService, ItemsService],
})
export class AppModule {}
