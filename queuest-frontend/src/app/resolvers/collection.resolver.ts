import {ActivatedRouteSnapshot, ResolveFn} from "@angular/router";
import {EMPTY, Observable} from "rxjs";
import {inject} from "@angular/core";
import {CollectionsService} from "../api/services";
import {Collection} from "../api/models/collection";

export const collectionResolver: ResolveFn<Collection> = (route: ActivatedRouteSnapshot): Observable<Collection> => {
  const collectionIdParam: string | null = findParam(ROUTER_PARAM_COLLECTION_ID, route);
  if (!collectionIdParam) {
    return EMPTY;
  }
  const collectionId: number = +collectionIdParam;
  return inject(CollectionsService).collectionControllerGetCollection({collectionId:collectionId});
}

export const ROUTER_PARAM_COLLECTION_ID: string = 'collectionId';
export function findParam(name: string, route: ActivatedRouteSnapshot): string | null {
  const value = route.params[name];
  if (value) {
    return value;
  }
  if (route.parent) {
    return findParam(name, route.parent);
  }
  return null;
}
