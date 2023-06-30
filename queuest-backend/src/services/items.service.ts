import { HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ItemEntity } from '../persistence/entities/item.entity';
import { Graph } from '../models/graph';
import { GraphService } from './graph.service';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import cloneDeep from 'lodash.clonedeep';
import { Item } from '../models/item';
import { CollectionService } from './collection.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
    CollectionItemEntity,
    CollectionItemType,
} from '../persistence/entities/collection-item.entity';
import { ItemRepository } from '../persistence/repositories/item.repository';
import { CollectionEntity } from '../persistence/entities/collection.entity';

@Injectable()
export class ItemsService {
    private readonly logger = new Logger(ItemsService.name);

    relations: Map<number, number[]> = new Map<number, number[]>();
    relationsInverted: Map<number, number[]> = new Map<number, number[]>();

    constructor(
        private readonly graphService: GraphService,
        private readonly collectionService: CollectionService,
        private itemRepository: ItemRepository,
        @InjectRepository(CollectionItemEntity)
        private collectionItemRepository: Repository<CollectionItemEntity>,
    ) {}

    private static mapToItem(cie: CollectionItemEntity): Item {
        const result = new Item();
        result.id = cie.id;
        result.type = cie.type;
        switch (cie.type) {
            case CollectionItemType.ITEM:
                console.log(
                    `We are in the switch ITEM ${JSON.stringify(cie)} ${
                        cie.item?.name
                    } ${cie.item?.name ?? ''}`,
                );
                result.name = cie.item?.name ?? '';
                break;
            case CollectionItemType.COLLECTION:
                result.name = cie.collection?.name ?? '';
                break;
            default:
                throw new Error(
                    `No covertion for ${cie.type} type of the item.`,
                );
        }
        return result;
    }

    public async addItem(userUid: string, collectionId: number, item: Item) {
        if (item.id != null) {
            throw new HttpException(
                `Can't create item with existing ID`,
                HttpStatus.BAD_REQUEST,
            );
        }
        const collection: CollectionEntity =
            await this.collectionService.getCollection(userUid, collectionId);
        const newItemEntity: ItemEntity = new ItemEntity();
        newItemEntity.name = item.name;
        const itemEntity: ItemEntity = await this.itemRepository.save(
            newItemEntity,
            { reload: true },
        );
        const newCollectionItemEntity: CollectionItemEntity =
            new CollectionItemEntity();
        this.logger.log('item entity ', JSON.stringify(itemEntity));
        newCollectionItemEntity.item = itemEntity;
        newCollectionItemEntity.collection = collection;
        newCollectionItemEntity.type = CollectionItemType.ITEM;
        await this.collectionItemRepository.save(newCollectionItemEntity);
    }

    async getItemsSorted(
        userUid: string,
        collectionId: number,
    ): Promise<Item[]> {
        const collection: CollectionEntity =
            await this.collectionService.getCollection(userUid, collectionId);
        const itemEntitySorted = (
            await this.getItemEntitySorted(collection)
        ).map((item) => ItemsService.mapToItem(item));
        return itemEntitySorted;
    }

    addRelation(relation: ItemRelation) {
        this.removeRelationFromTo(relation.to, relation.from);
        if (!this.relations.has(relation.from)) {
            this.relations.set(relation.from, []);
        }
        if (!this.relationsInverted.has(relation.to)) {
            this.relationsInverted.set(relation.to, []);
        }
        const index = this.relations
            .get(relation.from)
            ?.findIndex((value) => value == relation.to);
        if (index == -1) this.relations.get(relation.from)?.push(relation.to);

        const indexInverted = this.relationsInverted
            .get(relation.to)
            ?.findIndex((value) => value == relation.from);
        if (indexInverted == -1)
            this.relationsInverted.get(relation.to)?.push(relation.from);
    }

    deleteRelation(relation: ItemRelation) {
        this.removeRelationFromTo(relation.from, relation.to);
        this.removeRelationFromTo(relation.to, relation.from);
    }

    // getLastItem(): CollectionItemEntity | undefined {
    //     if (this.items.length) {
    //         return this.items[this.items.length - 1];
    //     }
    // }

    async getBestPairs(
        userUid: string,
        collectionId: number,
        size: number,
    ): Promise<ItemPair[]> {
        const collection: CollectionEntity =
            await this.collectionService.getCollection(userUid, collectionId);
        const itemsSorted = await this.getItemEntitySorted(collection);
        const fromArray = cloneDeep(itemsSorted).sort(
            (i1, i2) =>
                (this.relations.get(i1.id)?.length ?? 0) +
                (this.relationsInverted.get(i1.id)?.length ?? 0) +
                -(this.relations.get(i2.id)?.length ?? 0) +
                -(this.relationsInverted.get(i2.id)?.length ?? 0),
        );
        // return this.getBestConnectedPairs(size, fromArray, itemsSorted);
        return [];
    }

    async getBestPair(
        collection: CollectionEntity,
        id: number,
        exclude?: number[],
    ) {
        //TODO:
        const itemOptional = await this.collectionItemRepository.findOneBy({
            id: id,
        });
        if (itemOptional === null) {
            return undefined;
        }
        const item: CollectionItemEntity = itemOptional;
        const itemsSorted = await this.getItemEntitySorted(collection);
        const itemPosition = itemsSorted.findIndex((item) => item.id == id);
        if (
            itemPosition === 0 &&
            this.isThereRelationFromTo(item.id, itemsSorted[1].id)
        ) {
            return undefined;
        }
        if (
            itemPosition === itemsSorted.length - 1 &&
            this.isThereRelationFromTo(
                itemsSorted[itemsSorted.length - 2].id,
                item.id,
            )
        ) {
            return undefined;
        }
        if (
            this.isThereRelationFromTo(
                itemsSorted[itemPosition - 1].id,
                item.id,
            ) &&
            this.isThereRelationFromTo(
                item.id,
                itemsSorted[itemPosition + 1].id,
            )
        ) {
            return undefined;
        }
        const excludeSet = exclude
            ? new Set<number>(exclude)
            : new Set<number>();
        const bestPairForItem = this.getBestPairForItem(
            id,
            itemsSorted,
            excludeSet,
        );
        if (!bestPairForItem) return undefined;
        if (excludeSet.has(bestPairForItem.id)) return undefined;
        const itemPair = this.itemPairFromItems(item, bestPairForItem);
        if (!!itemPair.relation) return undefined;
        return itemPair;
    }

    private async getItemEntitySorted(
        collection: CollectionEntity,
    ): Promise<CollectionItemEntity[]> {
        const items = await this.collectionItemRepository.findBy({
            collection: { id: collection.id },
        });
        const graph: Graph = new Graph(items.length);
        this.getEdges(items, graph);
        const result: CollectionItemEntity[] = [];
        this.graphService
            .topologicalSort(graph)
            .forEach((ind) => result.push(items[ind]));
        return result;
    }

    private getBestConnectedPairs(
        size: number,
        fromArray: CollectionItemEntity[],
        itemsSorted: CollectionItemEntity[],
    ) {
        const result = [];
        let i = 0;
        const exclude = new Set<number>();
        while (result.length < size && i < fromArray.length) {
            const item = fromArray[i];
            this.logger.log(`item ${JSON.stringify(item)}`);
            const bestPairForItem = this.getBestPairForItem(
                item.id,
                itemsSorted,
                exclude,
            );
            if (!!bestPairForItem) {
                exclude.add(item.id);
                exclude.add(bestPairForItem.id);
                const itemPair = this.itemPairFromItems(item, bestPairForItem);
                result.push(itemPair);
            }
            i++;
        }
        return result;
    }

    private itemPairFromItems(
        item: CollectionItemEntity,
        bestPairForItem: CollectionItemEntity,
    ) {
        let itemRelation = undefined;
        if (this.isThereRelationFromTo(item.id, bestPairForItem.id)) {
            itemRelation = new ItemRelation(item.id, bestPairForItem.id);
        } else if (this.isThereRelationFromTo(bestPairForItem.id, item.id)) {
            itemRelation = new ItemRelation(bestPairForItem.id, item.id);
        }
        return new ItemPair(
            ItemsService.mapToItem(item),
            ItemsService.mapToItem(bestPairForItem),
            itemRelation,
        );
    }

    private getBestPairForItem(
        itemId: number,
        itemsList: CollectionItemEntity[],
        exclude: Set<number>,
    ): CollectionItemEntity | undefined {
        const itemPosition = itemsList.findIndex((item) => item.id == itemId);
        if (itemPosition < 0)
            throw new Error(`There is no item with ${itemId}`);
        const positions: Map<number, number> = new Map();
        for (let i = 0; i < itemsList.length; i++) {
            positions.set(itemsList[i].id, i);
        }
        const lastIdx = !this.relations.has(itemId)
            ? itemsList.length - 1
            : this.relations
                  .get(itemId)!
                  .map((id) => positions.get(id)!)
                  .reduce(
                      (prevValue, currentValue) =>
                          Math.min(prevValue, currentValue),
                      itemsList.length - 1,
                  );
        const firstIdx = !this.relationsInverted.has(itemId)
            ? 0
            : this.relationsInverted
                  .get(itemId)!
                  .map((id) => positions.get(id)!)
                  .reduce(
                      (prevValue, currentValue) =>
                          Math.max(prevValue, currentValue),
                      0,
                  );
        const relationPosition =
            Math.abs(itemPosition - firstIdx) > Math.abs(itemPosition - lastIdx)
                ? Math.ceil((itemPosition + firstIdx) / 2)
                : Math.floor((itemPosition + lastIdx) / 2);
        let backupItem = undefined;
        let resortItem = undefined;
        for (let i = 0; i < itemsList.length * 2; i++) {
            const position =
                relationPosition + (2 * (i % 2) - 1) * Math.ceil(i / 2);
            if (position < 0 || position >= itemsList.length) {
                continue;
            }
            const itemForRelation = itemsList[position];
            if (
                !backupItem &&
                itemForRelation.id !== itemId &&
                !exclude.has(itemForRelation.id)
            ) {
                backupItem = itemForRelation;
            }
            if (!resortItem && itemForRelation.id !== itemId) {
                resortItem = itemForRelation;
            }
            if (
                itemForRelation.id === itemId ||
                exclude.has(itemForRelation.id)
            ) {
                continue;
            }
            if (!this.isThereRelation(itemId, itemForRelation.id)) {
                return itemForRelation;
            }
        }
        if (!!backupItem) return backupItem;
        if (!!resortItem) return resortItem;
        return undefined;
    }

    private removeRelationFromTo(from: number, to: number) {
        if (this.relations.has(from)) {
            const index = this.relations
                .get(from)
                ?.findIndex((value) => value == to);
            if ((index || index === 0) && index > -1)
                this.relations.get(from)?.splice(index, 1);
        }
        if (this.relationsInverted.has(to)) {
            const index = this.relationsInverted
                .get(to)
                ?.findIndex((value) => value == from);
            if ((index || index === 0) && index > -1)
                this.relations.get(to)?.splice(index, 1);
        }
    }

    private getEdges(items: CollectionItemEntity[], graph: Graph) {
        for (let i = 0; i < items.length; i++) {
            const itemEntity = items[i];
            const relations = this.relations.get(itemEntity.id);
            if (relations && relations.length > 0) {
                relations.forEach((value) => {
                    const j = items.findIndex((v) => value === v.id);
                    graph.addEdge(i, j);
                });
            }
        }
    }

    private isThereRelation(itemAId: number, itemBId: number) {
        return (
            this.isThereRelationFromTo(itemAId, itemBId) ||
            this.isThereRelationFromTo(itemBId, itemAId)
        );
    }

    private isThereRelationFromTo(fromId: number, toId: number) {
        if (this.relations.has(fromId))
            return (
                0 <=
                this.relations.get(fromId)!.findIndex((idx) => idx === toId)
            );
        return false;
    }
}
