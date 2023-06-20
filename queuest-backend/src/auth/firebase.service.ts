import { Injectable } from '@nestjs/common';
import { app, ServiceAccount } from 'firebase-admin';
import * as firebase from 'firebase-admin';
import * as serviceAccount from '../firebase-adminsdk.json';

const firebaseParams: ServiceAccount = {
    projectId: serviceAccount.project_id,
    privateKey: serviceAccount.private_key,
    clientEmail: serviceAccount.client_email,
};

@Injectable()
export class FirebaseService {
    private defaultApp: app.App;

    constructor() {
        this.defaultApp = firebase.initializeApp({
            credential: firebase.credential.cert(firebaseParams),
        });
    }

    verifyAsync(token: string): Promise<any> {
        return this.defaultApp
            .auth()
            .verifyIdToken(token)
            .then(async (decodedToken) => {
                console.log('Decoded token', decodedToken);
                const user: any = {
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
