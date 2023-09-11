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


@Injectable({
  providedIn: 'root',
})
export class ItemsRelationService extends BaseService {
  constructor(
    config: ApiConfiguration,
    http: HttpClient
  ) {
    super(config, http);
  }

  /**
   * Path part for operation itemRelationsControllerAddItem
   */
  static readonly ItemRelationsControllerAddItemPath = '/relations/{fromId}/{toId}';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemRelationsControllerAddItem()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemRelationsControllerAddItem$Response(params: {
    fromId: number;
    toId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsRelationService.ItemRelationsControllerAddItemPath, 'post');
    if (params) {
      rb.path('fromId', params.fromId, {});
      rb.path('toId', params.toId, {});
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
   * To access the full response (for headers, for example), `itemRelationsControllerAddItem$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemRelationsControllerAddItem(params: {
    fromId: number;
    toId: number;
  },
  context?: HttpContext

): Observable<void> {

    return this.itemRelationsControllerAddItem$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

  /**
   * Path part for operation itemRelationsControllerGetItems
   */
  static readonly ItemRelationsControllerGetItemsPath = '/relations/{itemAId}/{itemBId}';

  /**
   * This method provides access to the full `HttpResponse`, allowing access to response headers.
   * To access only the response body, use `itemRelationsControllerGetItems()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemRelationsControllerGetItems$Response(params: {
    itemAId: number;
    itemBId: number;
  },
  context?: HttpContext

): Observable<StrictHttpResponse<void>> {

    const rb = new RequestBuilder(this.rootUrl, ItemsRelationService.ItemRelationsControllerGetItemsPath, 'delete');
    if (params) {
      rb.path('itemAId', params.itemAId, {});
      rb.path('itemBId', params.itemBId, {});
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
   * To access the full response (for headers, for example), `itemRelationsControllerGetItems$Response()` instead.
   *
   * This method doesn't expect any request body.
   */
  itemRelationsControllerGetItems(params: {
    itemAId: number;
    itemBId: number;
  },
  context?: HttpContext

): Observable<void> {

    return this.itemRelationsControllerGetItems$Response(params,context).pipe(
      map((r: StrictHttpResponse<void>) => r.body as void)
    );
  }

}
