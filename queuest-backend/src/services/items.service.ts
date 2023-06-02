import {Injectable} from '@nestjs/common';
import {ItemEntity} from '../persistence/entities/item.entity';
import {Graph} from '../models/graph';
import {GraphService} from './graph.service';
import {ItemRelation} from '../models/item-relation';
import {ItemPair} from '../models/item-pair';
import {ItemPairFilter} from '../controllers/filter/item-pair-filter';
import cloneDeep from 'lodash.clonedeep';

@Injectable()
export class ItemsService {
    items: ItemEntity[] = [];
    relations: Map<number, number[]> = new Map<number, number[]>();

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
        const index = this.relations
            .get(relation.from)
            ?.findIndex((value) => value == relation.to);
        if (index == -1) this.relations.get(relation.from)?.push(relation.to);
    }

    deleteRelation(relation: ItemRelation) {
        this.removeRelationFromTo(relation.from, relation.to);
        this.removeRelationFromTo(relation.to, relation.from);
    }

    getBestPairs(filter: ItemPairFilter): ItemPair[] {
        const fromArray = cloneDeep(this.items).sort(
            (i1, i2) =>
                -(this.relations.get(i1.id)?.length ?? 0) +
                (2 * Math.random() - 1) +
                (this.relations.get(i2.id)?.length ?? 0),
        );
        const toArray = cloneDeep(fromArray);
        const result = [];
        let i = 0;
        let j = 1;
        while (result.length < filter.size && i < fromArray.length) {
            const item1 = fromArray[i];
            const item2 = toArray[j];
            if (item1.id !== item2.id) {
                let itemRelation = undefined;
                const indexOf1 = this.relations
                    .get(item1.id)
                    ?.findIndex((v) => v === item2.id);
                const indexOf2 = this.relations
                    .get(item2.id)
                    ?.findIndex((v) => v === item1.id);
                if ((indexOf1 ? indexOf1 : -1) >= 0) {
                    itemRelation = new ItemRelation(item1.id, item2.id);
                } else if ((indexOf2 ? indexOf2 : -1) >= 0) {
                    itemRelation = new ItemRelation(item2.id, item1.id);
                }
                if (!itemRelation) {
                    const itemPair = new ItemPair(item1, item2, itemRelation);
                    result.push(itemPair);
                }
                j = (j + 1) % fromArray.length;
            } else {
                j = (j + 2) % fromArray.length;
            }
            i++;
        }
        i = 0;
        j = 1;
        while (result.length < filter.size && i < fromArray.length) {
            const item1 = fromArray[i];
            const item2 = toArray[j];
            if (item1.id !== item2.id) {
                let itemRelation = undefined;
                const indexOf1 = this.relations
                    .get(item1.id)
                    ?.findIndex((v) => v === item2.id);
                const indexOf2 = this.relations
                    .get(item2.id)
                    ?.findIndex((v) => v === item1.id);
                if ((indexOf1 ? indexOf1 : -1) >= 0) {
                    itemRelation = new ItemRelation(item1.id, item2.id);
                } else if ((indexOf2 ? indexOf2 : -1) >= 0) {
                    itemRelation = new ItemRelation(item2.id, item1.id);
                }
                if (!!itemRelation) {
                    const itemPair = new ItemPair(item1, item2, itemRelation);
                    result.push(itemPair);
                }
                j = (j + 1) % fromArray.length;
            } else {
                j = (j + 2) % fromArray.length;
            }
            i++;
        }
        return result;
    }

    private removeRelationFromTo(from: number, to: number) {
        if (this.relations.has(from)) {
            const index = this.relations
                .get(from)
                ?.findIndex((value) => value == to);
            if ((index || index === 0) && index > -1)
                this.relations.get(from)?.splice(index, 1);
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
}
