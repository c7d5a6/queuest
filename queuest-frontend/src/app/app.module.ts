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
import { CalibrateCollectionComponent } from './components/calibrate-collection/calibrate-collection.component';
import { initializeApp, provideFirebaseApp } from '@angular/fire/app';
import { getAuth, provideAuth } from '@angular/fire/auth';
import { FireAuthService } from './services/fire-auth.service';
import { FirebaseAuthInterceptor } from './interceptors/firebase-auth.interceptor';
import { AngularFireModule } from '@angular/fire/compat';
import { LoginComponent } from './components/login/login.component';
import { CollectionsComponent } from './components/collections/collections/collections.component';
import { CollectionsPageComponent } from './pages/collections-page/collections-page.component';
import { CollectionsSidepanelComponent } from './components/collections/collections-sidepanel/collections-sidepanel.component';
import { CollectionCardComponent } from './components/collections/collection-card/collection-card.component';
import { AddCollectionComponent } from './components/add-collection/add-collection.component';
import { CollectionPageComponent } from './pages/collection-page/collection-page.component';
import { TestPageComponent } from './pages/test-page/test-page.component';

@NgModule({
    declarations: [
        AppComponent,
        ListComponent,
        PairsComponent,
        AddItemComponent,
        PairComponent,
        CalibrateItemComponent,
        CalibrateCollectionComponent,
        LoginComponent,
        CollectionsComponent,
        CollectionsPageComponent,
        CollectionsSidepanelComponent,
        CollectionCardComponent,
        AddCollectionComponent,
        CollectionPageComponent,
        TestPageComponent,
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
        provideAuth(() => getAuth()),
    ],
    providers: [
        FireAuthService,
        {
            provide: HTTP_INTERCEPTORS,
            useClass: FirebaseAuthInterceptor,
            multi: true,
        },
    ],
    bootstrap: [AppComponent],
})
export class AppModule {}
