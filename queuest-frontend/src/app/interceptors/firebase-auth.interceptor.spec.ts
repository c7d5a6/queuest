import { TestBed } from '@angular/core/testing';

import { FirebaseAuthInterceptor } from './firebase-auth.interceptor';

describe('FirebaseAuthService', () => {
    let service: FirebaseAuthInterceptor;

    beforeEach(() => {
        TestBed.configureTestingModule({});
        service = TestBed.inject(FirebaseAuthInterceptor);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });
});
