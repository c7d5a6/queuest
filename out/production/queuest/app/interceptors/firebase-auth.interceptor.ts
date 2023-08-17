import { Injectable } from '@angular/core';
import {
    HttpEvent,
    HttpHandler,
    HttpInterceptor,
    HttpRequest,
} from '@angular/common/http';
import { FireAuthService } from '../services/fire-auth.service';
import { from, lastValueFrom, Observable } from 'rxjs';

@Injectable({
    providedIn: 'root',
})
export class FirebaseAuthInterceptor implements HttpInterceptor {
    constructor(private fireAuthService: FireAuthService) {}

    intercept(
        req: HttpRequest<any>,
        next: HttpHandler,
    ): Observable<HttpEvent<any>> {
        return from(this.handle(req, next));
    }

    async handle(req: HttpRequest<any>, next: HttpHandler) {
        const token = await this.fireAuthService.getToken();
        if (!token) {
            return await lastValueFrom(next.handle(req));
        }
        const req1 = req.clone({
            headers: req.headers.set('Authorization', `Bearer ${token}`),
        });
        return await lastValueFrom(next.handle(req1));
    }
}
