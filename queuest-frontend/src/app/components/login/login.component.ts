import { Component } from '@angular/core';
import { FireAuthService } from '../../services/fire-auth.service';

@Component({
    selector: 'app-login',
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.scss'],
})
export class LoginComponent {
    constructor(private fireAuthService: FireAuthService) {}

    get loggedIn(): boolean {
        return this.fireAuthService.isLoggedIn;
    }

    get userName(): string {
        const name = this.fireAuthService?.userData?.displayName;
        return name ? name : 'Logged In';
    }

    login() {
        this.GoogleAuth();
    }

    GoogleAuth(): void {
        this.fireAuthService.GoogleAuth();
    }

    logOut(): void {
        this.fireAuthService.SignOut();
    }
}
