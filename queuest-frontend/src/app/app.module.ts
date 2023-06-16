import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {HttpClientModule} from '@angular/common/http';
import { environment } from '../environments/environment';

import {AppRoutingModule} from './app-routing.module';
import {AppComponent} from './app.component';
import { ListComponent } from './components/list/list.component';
import {ApiModule} from "./api/api.module";
import { PairsComponent } from './components/pairs/pairs.component';
import { AddItemComponent } from './components/add-item/add-item.component';
import { PairComponent } from './components/pairs/pair/pair.component';
import {ReactiveFormsModule} from "@angular/forms";
import { CalibrateItemComponent } from './components/calibrate-item/calibrate-item.component';

@NgModule({
  declarations: [
    AppComponent,
    ListComponent,
    PairsComponent,
    AddItemComponent,
    PairComponent,
    CalibrateItemComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    ReactiveFormsModule.withConfig({warnOnNgModelWithFormControl: 'always'}),
    ApiModule.forRoot({rootUrl: environment.application.apiUrl}),
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {
}
