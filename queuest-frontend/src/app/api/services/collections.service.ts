/* tslint:disable */
/* eslint-disable */
import { Injectable } from '@angular/core';
import { HttpClient, HttpResponse, HttpContext } from '@angular/common/http';
import { BaseService } from '../base-service';
import { ApiConfiguration } from '../api-configuration';
import { StrictHttpResponse } from '../strict-http-response';
import { RequestBuilder } from '../request-builder';
import { Observable } from 'rxjs';
import { map, filter } from 'rxjs/operators';

import { Collection } from '../models/collection';

@Injectable({
  providedIn: 'root',
})
export class CollectionsService extends BaseService {
  constructor(
    config: ApiConfiguration,
    http: HttpClient
  ) {
    super(config, http);
  }

  /**
   * Path part for operation collectionControllerGetCurrentUserCollections
   */
  static readonly CollectionControllerGetCurrentUserCollectionsPath = '/collections';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `collectionControllerGetCurrentUserCollections()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCurrentUserCollections$Response(params?: {
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Array<Collection>>> {

    const rb = new RequestBuilder(this.rootUrl, CollectionsService.CollectionControllerGetCurrentUserCollectionsPath, 'get');
    if (params) {
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<Array<Collection>>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `collectionControllerGetCurrentUserCollections$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCurrentUserCollections(params?: {
  },
  context?: HttpContext

): Observable<Array<Collection>> {

    return this.collectionControllerGetCurrentUserCollections$Response(params,context).pipe(
      map((r: StrictHttpResponse<Array<Collection>>) => r.body as Array<Collection>)
    );
  }

  /**
   * Path part for operation collectionControllerAddCollection
   */
  static readonly CollectionControllerAddCollectionPath = '/collections';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `collectionControllerAddCollection()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  collectionControllerAddCollection$Response(params: {
    body: Collection
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, CollectionsService.CollectionControllerAddCollectionPath, 'post');
    if (params) {
      rb.body(params.body, 'application/json');
    }

    return this.http.request(rb.build({
      responseType: 'text',
      accept: '*/*',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return (r as HttpResponse<any>).clone({ body: undefined }) as StrictHttpResponse<void>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `collectionControllerAddCollection$Response()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  collectionControllerAddCollection(params: {
    body: Collection
  },
  context?: HttpContext

): Observable<void> {

    return this.collectionControllerAddCollection$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

  /**
   * Path part for operation collectionControllerGetCollection
   */
  static readonly CollectionControllerGetCollectionPath = '/collections/{collectionId}';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `collectionControllerGetCollection()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCollection$Response(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Collection>> {

    const rb = new RequestBuilder(this.rootUrl, CollectionsService.CollectionControllerGetCollectionPath, 'get');
    if (params) {
      rb.path('collectionId', params.collectionId, {});
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<Collection>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `collectionControllerGetCollection$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCollection(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<Collection> {

    return this.collectionControllerGetCollection$Response(params,context).pipe(
      map((r: StrictHttpResponse<Collection>) => r.body as Collection)
    );
  }

  /**
   * Path part for operation collectionControllerGetCurrentUserFavoriteCollections
   */
  static readonly CollectionControllerGetCurrentUserFavoriteCollectionsPath = '/collections/fav';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `collectionControllerGetCurrentUserFavoriteCollections()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCurrentUserFavoriteCollections$Response(params?: {
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Array<Collection>>> {

    const rb = new RequestBuilder(this.rootUrl, CollectionsService.CollectionControllerGetCurrentUserFavoriteCollectionsPath, 'get');
    if (params) {
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<Array<Collection>>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `collectionControllerGetCurrentUserFavoriteCollections$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  collectionControllerGetCurrentUserFavoriteCollections(params?: {
  },
  context?: HttpContext

): Observable<Array<Collection>> {

    return this.collectionControllerGetCurrentUserFavoriteCollections$Response(params,context).pipe(
      map((r: StrictHttpResponse<Array<Collection>>) => r.body as Array<Collection>)
    );
  }

}
