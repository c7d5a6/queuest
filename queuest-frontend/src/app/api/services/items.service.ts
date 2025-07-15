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

import { CollectionWithItems } from '../models/collection-with-items';
import { Item } from '../models/item';
import { ItemPair } from '../models/item-pair';

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
  static readonly ItemsControllerGetItemsPath = '/collections/{collectionId}/items';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetItems()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetItems$Response(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<CollectionWithItems>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetItemsPath, 'get');
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
        return r as StrictHttpResponse<CollectionWithItems>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetItems$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetItems(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<CollectionWithItems> {

    return this.itemsControllerGetItems$Response(params,context).pipe(
      map((r: StrictHttpResponse<CollectionWithItems>) => r.body as CollectionWithItems)
    );
  }

  /**
   * Path part for operation itemsControllerAddItem
   */
  static readonly ItemsControllerAddItemPath = '/collections/{collectionId}/items';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerAddItem()` instead.
   *
   * This method sends `application/json` and handles request body of type `application/json`.
   */
  itemsControllerAddItem$Response(params: {
    collectionId: number;
    body: Item
  },
  context?: HttpContext

): Observable<StrictHttpResponse<number>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerAddItemPath, 'post');
    if (params) {
      rb.path('collectionId', params.collectionId, {});
      rb.body(params.body, 'application/json');
    }

    return this.http.request(rb.build({
      responseType: 'json',
      accept: 'application/json',
      context: context
    })).pipe(
      filter((r: any) => r instanceof HttpResponse),
      map((r: HttpResponse<any>) => {
        return (r as HttpResponse<any>).clone({ body: parseFloat(String((r as HttpResponse<any>).body)) }) as StrictHttpResponse<number>;
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
    collectionId: number;
    body: Item
  },
  context?: HttpContext

): Observable<number> {

    return this.itemsControllerAddItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<number>) => r.body as number)
    );
  }

  /**
   * Path part for operation itemsControllerDeleteItemFromCollection
   */
  static readonly ItemsControllerDeleteItemFromCollectionPath = '/collections/{collectionId}/items/{collectionItemId}';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerDeleteItemFromCollection()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerDeleteItemFromCollection$Response(params: {
    collectionId: number;
    collectionItemId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerDeleteItemFromCollectionPath, 'delete');
    if (params) {
      rb.path('collectionItemId', params.collectionItemId, {});
      rb.path('collectionId', params.collectionId, {});
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
   * To access the full response (for headers, for example), `itemsControllerDeleteItemFromCollection$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerDeleteItemFromCollection(params: {
    collectionId: number;
    collectionItemId: number;
  },
  context?: HttpContext

): Observable<void> {

    return this.itemsControllerDeleteItemFromCollection$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

  /**
   * Path part for operation itemsControllerGetLeastCalibratedItem
   */
  static readonly ItemsControllerGetLeastCalibratedItemPath = '/collections/{collectionId}/items/least-calibrated';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetLeastCalibratedItem()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetLeastCalibratedItem$Response(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<Item>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetLeastCalibratedItemPath, 'get');
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
        return r as StrictHttpResponse<Item>;
      })
    );
  }

  /**
   * This method provides access only to the response body.
   * To access the full response (for headers, for example), `itemsControllerGetLeastCalibratedItem$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetLeastCalibratedItem(params: {
    collectionId: number;
  },
  context?: HttpContext

): Observable<Item> {

    return this.itemsControllerGetLeastCalibratedItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<Item>) => r.body as Item)
    );
  }

  /**
   * Path part for operation itemsControllerGetBestPair
   */
  static readonly ItemsControllerGetBestPairPath = '/collections/{collectionId}/items/{id}/bestpair/{strict}';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemsControllerGetBestPair()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemsControllerGetBestPair$Response(params: {
    id: number;
    strict: boolean;
    exclude?: Array<number>;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<ItemPair>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerGetBestPairPath, 'get');
    if (params) {
      rb.path('id', params.id, {});
      rb.path('strict', params.strict, {});
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
    strict: boolean;
    exclude?: Array<number>;
  },
  context?: HttpContext

): Observable<ItemPair> {

    return this.itemsControllerGetBestPair$Response(params,context).pipe(
      map((r: StrictHttpResponse<ItemPair>) => r.body as ItemPair)
    );
  }

}
