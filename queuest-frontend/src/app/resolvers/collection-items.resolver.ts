import { ActivatedRouteSnapshot, ResolveFn } from '@angular/router';
import { EMPTY, Observable } from 'rxjs';
import { inject } from '@angular/core';
import { ItemsService } from '../api/services';
import { Item } from '../api/models/item';

export const collectionItemsResolver: ResolveFn<Array<Item>> = (
    route: ActivatedRouteSnapshot,
): Observable<Array<Item>> => {
    const collectionIdParam: string | null = findParam(
        ROUTER_PARAM_COLLECTION_ID,
        route,
    );
    if (!collectionIdParam) {
        return EMPTY;
    }
    const collectionId: number = +collectionIdParam;
    return inject(ItemsService).itemsControllerGetItems({
        collectionId: collectionId,
    });
};

export const ROUTER_PARAM_COLLECTION_ID = 'collectionId';
export function findParam(
    name: string,
    route: ActivatedRouteSnapshot,
): string | null {
    const value = route.params[name];
    if (value) {
        return value;
    }
    if (route.parent) {
        return findParam(name, route.parent);
    }
    return null;
}
