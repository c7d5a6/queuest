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

): Observable<StrictHttpResponse<Array<Item>>> {

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
        return r as StrictHttpResponse<Array<Item>>;
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

): Observable<Array<Item>> {

    return this.itemsControllerGetItems$Response(params,context).pipe(
      map((r: StrictHttpResponse<Array<Item>>) => r.body as Array<Item>)
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

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsService.ItemsControllerAddItemPath, 'post');
    if (params) {
      rb.path('collectionId', params.collectionId, {});
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
    collectionId: number;
    body: Item
  },
  context?: HttpContext

): Observable<void> {

    return this.itemsControllerAddItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

}
