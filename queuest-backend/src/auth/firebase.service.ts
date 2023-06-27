import { Injectable, Logger } from '@nestjs/common';
import * as firebase from 'firebase-admin';
import { app, ServiceAccount } from 'firebase-admin';
import * as serviceAccount from '../firebase-adminsdk.json';
import { FirebaseUser } from './firebase-user';

const firebaseParams: ServiceAccount = {
    projectId: serviceAccount.project_id,
    privateKey: serviceAccount.private_key,
    clientEmail: serviceAccount.client_email,
};

@Injectable()
export class FirebaseService {
    private readonly logger = new Logger(FirebaseService.name);

    private defaultApp: app.App;

    constructor() {
        this.defaultApp = firebase.initializeApp({
            credential: firebase.credential.cert(firebaseParams),
        });
    }

    verifyAsync(token: string): Promise<FirebaseUser> {
        return this.defaultApp
            .auth()
            .verifyIdToken(token)
            .then(async (decodedToken) => {
                const user: FirebaseUser = {
                    email: decodedToken.email ?? '',
                    displayName: decodedToken.uid ?? '',
                    uid: decodedToken.uid ?? '',
                    emailVerified: decodedToken.email_verified ?? false,
                    photoURL: decodedToken.picture ?? '',
                };
                return user;
            });
    }
}
