import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GraphService } from './services/graph.service';

@Module({
    imports: [],
    controllers: [AppController],
    providers: [AppService, GraphService],
})
export class AppModule {}
