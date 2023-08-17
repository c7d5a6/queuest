import {Injectable} from '@angular/core';
import { GoogleAuthProvider } from '@firebase/auth';
import {AngularFireAuth} from "@angular/fire/compat/auth";
import {User} from "../model/user";
import {firstValueFrom} from "rxjs";

@Injectable({
  providedIn: 'root',
})
export class FireAuthService {
  userData: any;

  constructor(
    private afAuth: AngularFireAuth,
    // private afs: AngularFirestore,
  ) {
    this.afAuth.authState.subscribe((user) => {
      this.saveUser(user);
    });
  }

  private saveUser(user: any) {
    if (user) {
      this.userData = user;
      localStorage.setItem(
        'fire.user',
        JSON.stringify(this.userData),
      );
    } else {
      localStorage.setItem('fire.user', 'null');
    }
  }

  get isLoggedIn(): boolean {
    const userString = localStorage.getItem('fire.user');
    const user = JSON.parse(userString ? userString : 'null');
    return user !== null && user.emailVerified !== false;
  }

  GoogleAuth() {
    return this.AuthLogin(new GoogleAuthProvider()).then((res: any) => {
      // if (res) {
      //   this.router.navigate(['dashboard']);
      // }
    });
  }

  async getToken() {
    const token = await firstValueFrom(this.afAuth.idToken);
    return token;
  }

  AuthLogin(provider: any) {
    return this.afAuth
      .signInWithPopup(provider)
      .then((result) => {
        // this.ngZone.run(() => {
        //   this.router.navigate(['dashboard']);
        // });
        let user = this.SetUserData(result.user);
        this.saveUser(user);
      })
      .catch((error) => {
        window.alert(error);
      });
  }

  /* Setting up user data when sign in with username/password,
sign up with username/password and sign in with social auth
provider in Firestore database using AngularFirestore + AngularFirestoreDocument service */
  SetUserData(user: any) {
      // const userRef: AngularFirestoreDocument<any> = this.afs.doc<any>(
      //     `users/${user.uid}`,
      // );
      const userData: User = {
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          emailVerified: user.emailVerified,
      };
      return userData;
      // return userRef.set(userData, {
      //     merge: true,
      // });
  }

  // Sign out
  SignOut() {
    return this.afAuth.signOut().then(() => {
      localStorage.removeItem('fire.user');
    });
  }
}
