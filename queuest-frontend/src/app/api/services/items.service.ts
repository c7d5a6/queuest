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

import { Item } from '../models/item';
import { ItemEntity } from '../models/item-entity';
import { ItemPair } from '../models/item-pair';
import { ItemRelation } from '../models/item-relation';

@Injectable({
  providedIn: 'root',
})
export class ItemsService extends BaseService {
  constructor(
    config: ApiConfiguration,
    http: HttpClient
  ) {
    super(config, http);
  }

  /**
   * Path part for operation itemsControllerGetItems
   */
  static readonly ItemsControllerGetItemsPath = '/items';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetItems()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetItems$Response(params?: {
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Array<ItemEntity>>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetItemsPath, 'get');
    if (params) {
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<Array<ItemEntity>>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetItems$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetItems(params?: {
  },
  context?: HttpContext

): Observable<Array<ItemEntity>> {

    return this.itemsControllerGetItems$Response(params,context).pipe(
      map((r: StrictHttpResponse<Array<ItemEntity>>) => r.body as Array<ItemEntity>)
    );
  }

  /**
   * Path part for operation itemsControllerAddItem
   */
  static readonly ItemsControllerAddItemPath = '/items';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerAddItem()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerAddItem$Response(params: {
    body: Item
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerAddItemPath, 'post');
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
   * To access the full response (for headers, for example), `itemsControllerAddItem$Response()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerAddItem(params: {
    body: Item
  },
  context?: HttpContext

): Observable<void> {

    return this.itemsControllerAddItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

  /**
   * Path part for operation itemsControllerGetBestPairs
   */
  static readonly ItemsControllerGetBestPairsPath = '/items/pairs';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetBestPairs()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetBestPairs$Response(params: {
    size: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Array<ItemPair>>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetBestPairsPath, 'get');
    if (params) {
      rb.query('size', params.size, {});
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<Array<ItemPair>>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetBestPairs$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetBestPairs(params: {
    size: number;
  },
  context?: HttpContext

): Observable<Array<ItemPair>> {

    return this.itemsControllerGetBestPairs$Response(params,context).pipe(
      map((r: StrictHttpResponse<Array<ItemPair>>) => r.body as Array<ItemPair>)
    );
  }

  /**
   * Path part for operation itemsControllerGetLastItem
   */
  static readonly ItemsControllerGetLastItemPath = '/items/last';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetLastItem()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetLastItem$Response(params?: {
  },
  context?: HttpContext

): Observable<StrictHttpResponse<ItemEntity>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetLastItemPath, 'get');
    if (params) {
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<ItemEntity>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetLastItem$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetLastItem(params?: {
  },
  context?: HttpContext

): Observable<ItemEntity> {

    return this.itemsControllerGetLastItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<ItemEntity>) => r.body as ItemEntity)
    );
  }

  /**
   * Path part for operation itemsControllerGetBestPair
   */
  static readonly ItemsControllerGetBestPairPath = '/items/{id}/bestpair';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetBestPair()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetBestPair$Response(params: {
    id: number;
    exclude?: Array<number>;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<ItemPair>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetBestPairPath, 'get');
    if (params) {
      rb.path('id', params.id, {});
      rb.query('exclude', params.exclude, {});
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return r as StrictHttpResponse<ItemPair>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetBestPair$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetBestPair(params: {
    id: number;
    exclude?: Array<number>;
  },
  context?: HttpContext

): Observable<ItemPair> {

    return this.itemsControllerGetBestPair$Response(params,context).pipe(
      map((r: StrictHttpResponse<ItemPair>) => r.body as ItemPair)
    );
  }

  /**
   * Path part for operation itemsControllerAddRelation
   */
  static readonly ItemsControllerAddRelationPath = '/items/relation';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerAddRelation()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerAddRelation$Response(params: {
    body: ItemRelation
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerAddRelationPath, 'post');
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
   * To access the full response (for headers, for example), `itemsControllerAddRelation$Response()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerAddRelation(params: {
    body: ItemRelation
  },
  context?: HttpContext

): Observable<void> {

    return this.itemsControllerAddRelation$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

  /**
   * Path part for operation itemsControllerDeleteRelation
   */
  static readonly ItemsControllerDeleteRelationPath = '/items/relation';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerDeleteRelation()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerDeleteRelation$Response(params: {
    body: ItemRelation
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerDeleteRelationPath, 'delete');
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
   * To access the full response (for headers, for example), `itemsControllerDeleteRelation$Response()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerDeleteRelation(params: {
    body: ItemRelation
  },
  context?: HttpContext

): Observable<void> {

    return this.itemsControllerDeleteRelation$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

}
