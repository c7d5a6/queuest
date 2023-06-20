import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { environment } from '../environments/environment';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { ListComponent } from './components/list/list.component';
import { ApiModule } from './api/api.module';
import { PairsComponent } from './components/pairs/pairs.component';
import { AddItemComponent } from './components/add-item/add-item.component';
import { PairComponent } from './components/pairs/pair/pair.component';
import { ReactiveFormsModule } from '@angular/forms';
import { CalibrateItemComponent } from './components/calibrate-item/calibrate-item.component';
import { initializeApp, provideFirebaseApp } from '@angular/fire/app';
import {
    getAnalytics,
    provideAnalytics,
    ScreenTrackingService,
    UserTrackingService,
} from '@angular/fire/analytics';
import { getAuth, provideAuth } from '@angular/fire/auth';
import { FireAuthService } from './services/fire-auth.service';
import { FirebaseAuthInterceptor } from './interceptors/firebase-auth.interceptor';
import { AngularFireModule } from '@angular/fire/compat';
import { LoginComponent } from './components/login/login.component';
import { ProfileComponent } from './components/profile/profile.component';

@NgModule({
    declarations: [
        AppComponent,
        ListComponent,
        PairsComponent,
        AddItemComponent,
        PairComponent,
        CalibrateItemComponent,
        LoginComponent,
    ],
    imports: [
        BrowserModule,
        HttpClientModule,
        ReactiveFormsModule.withConfig({
            warnOnNgModelWithFormControl: 'always',
        }),
        ApiModule.forRoot({ rootUrl: environment.application.apiUrl }),
        AppRoutingModule,
        AngularFireModule.initializeApp(environment.firebase),
        provideFirebaseApp(() => {
            console.log('*********MODULE*********', environment.firebase);
            return initializeApp(environment.firebase);
        }),
        provideAnalytics(() => getAnalytics()),
        provideAuth(() => getAuth()),
    ],
    providers: [
        FireAuthService,
        {
            provide: HTTP_INTERCEPTORS,
            useClass: FirebaseAuthInterceptor,
            multi: true,
        },
        ScreenTrackingService,
        UserTrackingService,
    ],
    bootstrap: [AppComponent],
})
export class AppModule {}
