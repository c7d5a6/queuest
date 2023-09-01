import { Component } from '@angular/core';
import { FireAuthService } from '../../services/fire-auth.service';
import { DialogService } from '@ngneat/dialog';
import { ProfileComponent } from '../profile/profile.component';

@Component({
    selector: 'app-login',
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.scss'],
})
export class LoginComponent {
    constructor(
        private fireAuthService: FireAuthService,
        private dialogService: DialogService,
    ) {}

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

    profile(): void {
        this.dialogService.open(ProfileComponent, {
            // data is typed based on the passed generic
            data: {
                title: 'asdasdsad',
            },
        });
    }
}
