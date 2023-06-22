import { Controller, Get, Logger, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from './auth/auth.guard';

@Controller()
export class AppController {
    private readonly logger = new Logger(AppController.name);

    @Get()
    getHello(): string {
        return 'hello';
    }

    @Get('/user')
    @UseGuards(AuthGuard)
    getHU(@Req() request: any): string {
        const requestElement: any = request.user;
        this.logger.log('request ', request.user);
        return `hello ${requestElement?.uid}!`;
    }
}
