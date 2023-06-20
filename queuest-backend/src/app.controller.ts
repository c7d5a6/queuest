import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from './auth/auth.guard';

@Controller()
export class AppController {
    @Get()
    getHello(): string {
        return 'hello';
    }

    @Get('/user')
    @UseGuards(AuthGuard)
    getHU(@Req() request: any): string {
        const requestElement: any = request.user;
        console.log('request ', request.user);
        return `hello ${requestElement?.uid}!`;
    }
}
