import { ActivatedRouteSnapshot, ResolveFn } from '@angular/router';
import { Collection } from '../api/models/collection';
import { Observable } from 'rxjs';
import { inject } from '@angular/core';
import { CollectionsService } from '../api/services';

export const collectionsResolver: ResolveFn<Array<Collection>> = (
    route: ActivatedRouteSnapshot,
): Observable<Array<Collection>> => {
    return inject(
        CollectionsService,
    ).collectionControllerGetCurrentUserCollections();
};
