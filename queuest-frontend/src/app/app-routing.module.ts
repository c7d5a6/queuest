import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { collectionsResolver } from './resolvers/collections.resolver';
import { CollectionsPageComponent } from './pages/collections-page/collections-page.component';
import { CollectionPageComponent } from './pages/collection-page/collection-page.component';
import { collectionItemsResolver } from './resolvers/collection-items.resolver';
import { collectionResolver } from './resolvers/collection.resolver';
import {favCollectionsResolver} from "./resolvers/favCollections.resolver";

const routes: Routes = [
    {
        path: '',
        component: CollectionsPageComponent,
        resolve: { collections: collectionsResolver, favCollections: favCollectionsResolver },
    },
    {
        path: 'collection/:collectionId',
        component: CollectionPageComponent,
        resolve: {
            items: collectionItemsResolver,
            collection: collectionResolver,
        },
    },
];

@NgModule({
    imports: [RouterModule.forRoot(routes)],
    exports: [RouterModule],
})
export class AppRoutingModule {}
