/* tslint:disable */
/* eslint-disable */
import { ItemEntity } from './item-entity';
import { ItemRelation } from './item-relation';
export interface ItemPair {
  item1: ItemEntity;
  item2: ItemEntity;
  relation?: ItemRelation;
}
