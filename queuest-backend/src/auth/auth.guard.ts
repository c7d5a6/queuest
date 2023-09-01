import { CanActivate, ExecutionContext, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { FirebaseService } from './firebase.service';
import { UserService } from '../services/user.service';

@Injectable()
export class AuthGuard implements CanActivate {
    private readonly logger = new Logger(AuthGuard.name);

    constructor(private firebaseService: FirebaseService, private userService: UserService) {}

    async canActivate(context: ExecutionContext): Promise<boolean> {
        const request = context.switchToHttp().getRequest();
        const token = this.extractTokenFromHeader(request);
        if (!token) {
            throw new UnauthorizedException();
        }
        try {
            const user = await this.firebaseService.verifyAsync(token);
            await this.userService.syncFirebaseUser(user);
            // 💡 We're assigning the user to the request object here
            // so that we can access it in our route handlers
            request['user'] = user;
        } catch (ex) {
            this.logger.error(ex);
            throw new UnauthorizedException();
        }
        return true;
    }

    private extractTokenFromHeader(request: Request) {
        const [type, token] = request.headers.authorization?.split(' ') ?? [];
        return type === 'Bearer' ? token : undefined;
    }
}
