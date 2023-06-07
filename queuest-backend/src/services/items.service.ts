import { Injectable } from '@nestjs/common';
import { ItemEntity } from '../persistence/entities/item.entity';
import { Graph } from '../models/graph';
import { GraphService } from './graph.service';
import { ItemRelation } from '../models/item-relation';
import { ItemPair } from '../models/item-pair';
import { ItemPairFilter } from '../controllers/filter/item-pair-filter';
import cloneDeep from 'lodash.clonedeep';

@Injectable()
export class ItemsService {
    items: ItemEntity[] = [];
    relations: Map<number, number[]> = new Map<number, number[]>();
    relationsInverted: Map<number, number[]> = new Map<number, number[]>();

    constructor(private readonly graphService: GraphService) {
        this.items.push(new ItemEntity(0, 'Pizza'));
        this.items.push(new ItemEntity(1, 'Sushi'));
        this.items.push(new ItemEntity(2, 'Burgers'));
        this.items.push(new ItemEntity(3, 'Ramen'));
        this.items.push(new ItemEntity(4, 'Star Wars'));
        this.items.push(new ItemEntity(5, 'The Lord of the Rings'));
        this.items.push(new ItemEntity(6, 'The Matrix'));
        this.items.push(new ItemEntity(7, 'Titanic'));
        this.items.push(new ItemEntity(8, 'Taking a warm bath'));
        this.items.push(new ItemEntity(9, 'Getting a massage'));
        this.items.push(new ItemEntity(10, 'Taking a walk in nature'));
        this.items.push(new ItemEntity(11, 'Taking a nap'));
        this.items.push(new ItemEntity(12, 'Harry Potter'));
        this.items.push(new ItemEntity(13, 'Bohemian Rhapsody'));
        this.items.push(new ItemEntity(14, 'Stairway to Heaven'));
        this.items.push(new ItemEntity(15, 'Chocolate'));
    }

    getItemsSorted(): ItemEntity[] {
        const graph: Graph = new Graph(this.items.length);
        this.getEdges(graph);
        const result: ItemEntity[] = [];
        this.graphService
            .topologicalSort(graph)
            .forEach((ind) => result.push(this.items[ind]));
        return result;
    }

    addItem(item: ItemEntity) {
        item.id = this.items.length;
        this.items.push(item);
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

    getBestPairs(filter: ItemPairFilter): ItemPair[] {
        const itemsSorted = this.getItemsSorted();
        const fromArray = cloneDeep(this.items).sort(
            (i1, i2) =>
                -(
                    (this.relations.get(i1.id)?.length ?? 0) +
                    (this.relationsInverted.get(i1.id)?.length ?? 0)
                ) +
                (2 * Math.random() - 1) +
                ((this.relations.get(i2.id)?.length ?? 0) +
                    (this.relationsInverted.get(i2.id)?.length ?? 0)),
        );
        const result = [];
        let i = 0;
        const exclude = new Set<number>();
        while (result.length < filter.size && i < fromArray.length) {
            const item = fromArray[i];
            const bestPairForItem = this.getBestPairForItem(
                item.id,
                itemsSorted,
                exclude,
            );
            if (!!bestPairForItem) {
                exclude.add(item.id);
                exclude.add(bestPairForItem.id);
                let itemRelation = undefined;
                if (this.isThereRelationFromTo(item.id, bestPairForItem.id)) {
                    itemRelation = new ItemRelation(
                        item.id,
                        bestPairForItem.id,
                    );
                } else if (
                    this.isThereRelationFromTo(bestPairForItem.id, item.id)
                ) {
                    itemRelation = new ItemRelation(
                        bestPairForItem.id,
                        item.id,
                    );
                }
                const itemPair = new ItemPair(
                    item,
                    bestPairForItem,
                    itemRelation,
                );
                result.push(itemPair);
            }
            i++;
        }
        return result;
    }

    private getBestPairForItem(
        itemId: number,
        itemsList: ItemEntity[],
        exclude: Set<number>,
    ): ItemEntity | undefined {
        const positions: Map<number, number> = new Map<number, number>();
        itemsList.forEach((value, index) => positions.set(value.id, index));
        const itemPosition = positions.get(itemId)!;
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

    private getEdges(graph: Graph) {
        for (let i = 0; i < this.items.length; i++) {
            const itemEntity = this.items[i];
            const relations = this.relations.get(itemEntity.id);
            if (relations && relations.length > 0) {
                relations.forEach((value) => {
                    const j = this.items.findIndex((v) => value === v.id);
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
