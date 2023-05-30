import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as fs from 'fs';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    app.enableCors();
    const config = new DocumentBuilder()
        .setTitle('Queuest api')
        .setDescription('The queuest API description')
        .setVersion('1.0')
        .build();
    const document = SwaggerModule.createDocument(app, config);
    fs.writeFileSync('../api/swagger-spec.json', JSON.stringify(document));
    SwaggerModule.setup('api', app, document);
    await app.listen(3001);
}
bootstrap();
