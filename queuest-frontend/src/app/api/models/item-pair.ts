/* tslint:disable */
/* eslint-disable */
import { Item } from './item';
import { ItemRelation } from './item-relation';
export interface ItemPair {
  item1: Item;
  item2: Item;
  relation?: ItemRelation;
}
