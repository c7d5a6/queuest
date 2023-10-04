import {HttpException, HttpStatus, Injectable, Logger} from '@nestjs/common';
import {ItemEntity} from '../persistence/entities/item.entity';
import {Graph} from '../models/graph';
import {GraphService} from './graph.service';
import {Item} from '../models/item';
import {CollectionService} from './collection.service';
import {InjectRepository} from '@nestjs/typeorm';
import {Repository} from 'typeorm';
import {CollectionItemEntity, CollectionItemType} from '../persistence/entities/collection-item.entity';
import {ItemRepository} from '../persistence/repositories/item.repository';
import {CollectionEntity} from '../persistence/entities/collection.entity';
import {Edges, ItemsRelationService} from "./items-relation.service";
import {UserService} from "./user.service";
import {ItemRelation} from "../models/item-relation";
import {ItemPair} from "../models/item-pair";
import {CollectionWithItems} from "../models/collection-with-items";

@Injectable()
export class ItemsService {
    private readonly logger = new Logger(ItemsService.name);

    constructor(
        private readonly userService: UserService,
        private readonly graphService: GraphService,
        private readonly collectionService: CollectionService,
        private readonly itemsRelationService: ItemsRelationService,
        private itemRepository: ItemRepository,
        @InjectRepository(CollectionItemEntity)
        private collectionItemRepository: Repository<CollectionItemEntity>,
    ) {
    }

    private static mapToItem(cie: CollectionItemEntity, calibrated: boolean | undefined): Item {
        const result = new Item();
        result.id = cie.id;
        result.type = cie.type;
        result.calibrated = calibrated;
        switch (cie.type) {
            case CollectionItemType.ITEM:
                result.name = cie.item?.name ?? '';
                break;
            case CollectionItemType.COLLECTION:
                result.name = cie.collection?.name ?? '';
                break;
            default:
                throw new Error(`No covertion for ${cie.type} type of the item.`);
        }
        return result;
    }

    private static calcCollectionCalibration(length: number, edge: Edges): number {
        if (length < 2)
            return 1;
        const desiredNumber = (length - 2) * 2 + 1;
        const outEdges = Array.from(edge.relations.values()).map(a => a.length).reduce((previousValue, currentValue) => previousValue + currentValue);
        const inEdges = Array.from(edge.relationsInverted.values()).map(a => a.length).reduce((previousValue, currentValue) => previousValue + currentValue);
        return (outEdges + inEdges) / 2.0 / desiredNumber ;
    }

    public async addItem(userUid: string, collectionId: number, item: Item): Promise<Number> {
        if (item.id != null) {
            throw new HttpException(`Can't create item with existing ID`, HttpStatus.BAD_REQUEST);
        }
        const collection: CollectionEntity = await this.collectionService.getCollection(userUid, collectionId);
        const newItemEntity: ItemEntity = new ItemEntity();
        newItemEntity.name = item.name;
        const itemEntity: ItemEntity = await this.itemRepository.save(newItemEntity, {reload: true});
        const newCollectionItemEntity: CollectionItemEntity = new CollectionItemEntity();
        this.logger.log('item entity ', JSON.stringify(itemEntity));
        newCollectionItemEntity.item = itemEntity;
        newCollectionItemEntity.collection = collection;
        newCollectionItemEntity.type = CollectionItemType.ITEM;
        const result = await this.collectionItemRepository.save(newCollectionItemEntity);
        return result.id;
    }

    public async deleteItem(userUid: string, collectionItemId: number): Promise<void> {
        const collectionItem: CollectionItemEntity | null = await this.collectionItemRepository.findOneBy({id: collectionItemId});
        if (collectionItem === null) {
            this.logger.error('Can\'t delete, item not found {} ', collectionItemId);
            return;
        }
        this.userService.checkUserAccess(userUid, collectionItem.collection.user);
        await this.itemsRelationService.removeRelationsForItem(collectionItem);
        await this.collectionItemRepository.remove(collectionItem);
    }

    async getItemsSorted(userUid: string, collectionId: number): Promise<CollectionWithItems> {
        const collection: CollectionEntity = await this.collectionService.getCollection(userUid, collectionId);
        const collectionItemEntities = await this.getItemEntitySorted(collection);
        const edge: Edges = await this.itemsRelationService.getRelationsMaps(collectionItemEntities);
        const items = collectionItemEntities.map((item, index, array) => {
                let calibrated = this.isItemCalibrated(array, edge, item, index);
                return ItemsService.mapToItem(item, calibrated);
            }
        );
        const calibrated = ItemsService.calcCollectionCalibration(items.length, edge);
        return {
            id: collectionId,
            items: items,
            calibrated: calibrated,
        };
    }

    async setGraphEdges(items: CollectionItemEntity[], graph: Graph): Promise<void> {
        const edge: Edges = await this.itemsRelationService.getRelationsMaps(items);
        this.setGraphEdgesByEdges(items, edge, graph);
    }

    async getBestPair(userUid: string, id: number, exclude?: number[]) {
        const itemFrom = await this.collectionItemRepository.findOneBy({
            id: id,
        });
        if (itemFrom === null) {
            return undefined;
        }
        this.userService.checkUserAccess(userUid, itemFrom.collection.user);
        const items = await this.collectionItemRepository.findBy({
            collection: {id: itemFrom.collection.id},
        });
        const graph: Graph = new Graph(items.length);
        const edge: Edges = await this.itemsRelationService.getRelationsMaps(items);
        await this.setGraphEdgesByEdges(items, edge, graph);
        const itemsSorted = this.getItemEntitySortedByGraph(graph, items);
        const itemPosition = itemsSorted.findIndex((item) => item.id == id);
        if (this.isItemCalibrated(itemsSorted, edge, itemFrom, itemPosition))
            return undefined;
        const excludeSet = exclude ? new Set<number>(exclude) : new Set<number>();
        const bestPairForItem = this.getBestPairForItem(id, itemsSorted, excludeSet, edge);
        if (!bestPairForItem) return undefined;
        if (excludeSet.has(bestPairForItem.id)) return undefined;
        const itemPair = this.itemPairFromItems(itemFrom, bestPairForItem, edge);
        if (!!itemPair.relation) return undefined;
        return itemPair;
    }

    private isItemCalibrated(sortedArray: CollectionItemEntity[], edge: Edges, item: CollectionItemEntity, itemIndex: number) {
        if (sortedArray.length <= 1)
            return true;
        const itemRelationsLength: number = edge.relations.has(item.id) ? edge.relations.get(item.id)?.length! : 0;
        const itemRelationsInvertedLength: number = edge.relationsInverted.has(item.id) ? edge.relationsInverted.get(item.id)?.length! : 0;
        if (itemRelationsLength + itemRelationsInvertedLength >= sortedArray.length - 1)
            return true;
        if (itemIndex === 0) {
            return this.isThereRelationFromTo(item.id, sortedArray[1].id, edge);
        }
        if (itemIndex === sortedArray.length - 1) {
            return this.isThereRelationFromTo(sortedArray[sortedArray.length - 2].id, item.id, edge);
        }
        return this.isThereRelationFromTo(item.id, sortedArray[itemIndex + 1].id, edge) &&
            this.isThereRelationFromTo(sortedArray[itemIndex - 1].id, item.id, edge);
    }

    private setGraphEdgesByEdges(items: CollectionItemEntity[], edge: Edges, graph: Graph) {
        for (let i = 0; i < items.length; i++) {
            const itemEntity = items[i];
            const relations = edge.relations.get(itemEntity.id);
            if (relations && relations.length > 0) {
                relations.forEach((value) => {
                    const j = items.findIndex((v) => value === v.id);
                    graph.addEdge(i, j);
                });
            }
        }
    }

    private async getItemEntitySorted(collection: CollectionEntity): Promise<CollectionItemEntity[]> {
        const items = await this.collectionItemRepository.findBy({
            collection: {id: collection.id},
        });
        const graph: Graph = new Graph(items.length);
        await this.setGraphEdges(items, graph);
        return this.getItemEntitySortedByGraph(graph, items);
    }

    private getItemEntitySortedByGraph(graph: Graph, items: CollectionItemEntity[]) {
        const result: CollectionItemEntity[] = [];
        this.graphService.topologicalSort(graph).forEach((ind) => result.push(items[ind]));
        return result;
    }

    private itemPairFromItems(item: CollectionItemEntity, bestPairForItem: CollectionItemEntity, edge: Edges) {
        let itemRelation = undefined;
        if (this.isThereRelationFromTo(item.id, bestPairForItem.id, edge)) {
            itemRelation = new ItemRelation(item.id, bestPairForItem.id);
        } else if (this.isThereRelationFromTo(bestPairForItem.id, item.id, edge)) {
            itemRelation = new ItemRelation(bestPairForItem.id, item.id);
        }
        return new ItemPair(ItemsService.mapToItem(item, undefined), ItemsService.mapToItem(bestPairForItem, undefined), itemRelation);
    }

    private getBestPairForItem(
        itemId: number,
        itemsList: CollectionItemEntity[],
        exclude: Set<number>,
        edge: Edges,
    ): CollectionItemEntity | undefined {
        const itemPosition = itemsList.findIndex((item) => item.id == itemId);
        if (itemPosition < 0) throw new Error(`There is no item with ${itemId}`);
        const positions: Map<number, number> = new Map();
        for (let i = 0; i < itemsList.length; i++) {
            positions.set(itemsList[i].id, i);
        }
        const lastIdx = !edge.relations.has(itemId)
            ? itemsList.length - 1
            : edge.relations
                .get(itemId)!
                .map((id) => positions.get(id)!)
                .reduce((prevValue, currentValue) => Math.min(prevValue, currentValue), itemsList.length - 1);
        const firstIdx = !edge.relationsInverted.has(itemId)
            ? 0
            : edge.relationsInverted
                .get(itemId)!
                .map((id) => positions.get(id)!)
                .reduce((prevValue, currentValue) => Math.max(prevValue, currentValue), 0);
        const relationPosition =
            Math.abs(itemPosition - firstIdx) > Math.abs(itemPosition - lastIdx)
                ? Math.ceil((itemPosition + firstIdx) / 2)
                : Math.floor((itemPosition + lastIdx) / 2);
        let backupItem = undefined;
        let resortItem = undefined;
        for (let i = 0; i < itemsList.length * 2; i++) {
            const position = relationPosition + (2 * (i % 2) - 1) * Math.ceil(i / 2);
            if (position < 0 || position >= itemsList.length) {
                continue;
            }
            const itemForRelation = itemsList[position];
            if (!backupItem && itemForRelation.id !== itemId && !exclude.has(itemForRelation.id)) {
                backupItem = itemForRelation;
            }
            if (!resortItem && itemForRelation.id !== itemId) {
                resortItem = itemForRelation;
            }
            if (itemForRelation.id === itemId || exclude.has(itemForRelation.id)) {
                continue;
            }
            if (!this.isThereRelation(itemId, itemForRelation.id, edge)) {
                return itemForRelation;
            }
        }
        if (!!backupItem) return backupItem;
        if (!!resortItem) return resortItem;
        return undefined;
    }

    private isThereRelation(itemAId: number, itemBId: number, edge: Edges) {
        return this.isThereRelationFromTo(itemAId, itemBId, edge) || this.isThereRelationFromTo(itemBId, itemAId, edge);
    }

    private isThereRelationFromTo(fromId: number, toId: number, edge: Edges) {
        if (edge.relations.has(fromId)) return 0 <= edge.relations.get(fromId)!.findIndex((idx) => idx === toId);
        return false;
    }
}
