import { Controller, Get, Logger, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from './auth/auth.guard';
import { ItemsService } from './services/items.service';
import { UserService } from './services/user.service';
import { UserEntity } from './persistence/entities/user.entity';
import { FirebaseUser } from './auth/firebase-user';

@Controller()
export class AppController {
    private readonly logger = new Logger(AppController.name);

    constructor(private readonly userService: UserService) {}

    @Get()
    getHello(): string {
        return 'hello';
    }

    @Get('/user')
    @UseGuards(AuthGuard)
    getHU(@Req() request: any): string {
        const requestElement: FirebaseUser = request.user;
        this.logger.log('request ', request.user);
        return `hello ${requestElement?.uid}!`;
    }

    @Get('/getUsers')
    async getUsers(@Req() request: any): Promise<UserEntity[]> {
        const users = await this.userService.findAll();
        return users;
    }

    @Post('/saveUser')
    saveUser(@Req() request: any): void {
        this.userService.save();
    }
}
