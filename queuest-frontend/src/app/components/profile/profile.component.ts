import { ChangeDetectionStrategy, Component } from '@angular/core';
import { DialogRef } from '@ngneat/dialog';
import { FireAuthService } from '../../services/fire-auth.service';

interface Data {
    userName: string;
}

@Component({
    selector: 'app-profile',
    templateUrl: './profile.component.html',
    styleUrls: ['./profile.component.scss'],
})
export class ProfileComponent {
    constructor(
        private ref: DialogRef<Data>,
        private fireAuthService: FireAuthService,
    ) {}

    get userName() {
        return this.fireAuthService.userData.displayName;
    }

    get photoURL() {
        return this.fireAuthService.userData.photoURL;
    }

    logOut(): void {
        this.fireAuthService.SignOut();
        this.ref.close();
    }
}
