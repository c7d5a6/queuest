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

    constructor(private readonly graphService: GraphService) {
        this.items.push(new ItemEntity(0, 'The Godfather'));
        this.items.push(new ItemEntity(1, 'The Shawshank Redemption'));
        this.items.push(new ItemEntity(2, 'The Dark Knight'));
        this.items.push(new ItemEntity(3, 'Pulp Fiction'));
        this.items.push(new ItemEntity(4, 'Forrest Gump'));
        this.items.push(new ItemEntity(5, 'The Matrix'));
        this.items.push(
            new ItemEntity(6, 'Star Wars: Episode IV - A New Hope'),
        );
        this.items.push(new ItemEntity(7, 'The Silence of the Lambs'));
        this.items.push(
            new ItemEntity(
                8,
                'The Lord of the Rings: The Fellowship of the Ring',
            ),
        );
        this.items.push(new ItemEntity(9, 'Goodfellas'));
        this.items.push(new ItemEntity(10, 'The Social Network'));
        this.items.push(new ItemEntity(11, 'Parasite'));
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
        const fromArray = cloneDeep(this.items).sort(() => Math.random() - 0.5);
        const toArray = cloneDeep(this.items).sort(() => Math.random() - 0.5);
        const result = [];
        let i = 0;
        while (result.length < filter.size) {
            const item1 = fromArray[i];
            const item2 = toArray[i];
            if (item1.id !== item2.id) {
                let itemRelation = undefined;
                if (
                    this.relations.has(item1.id)
                        ? this.relations
                              .get(item1.id)
                              ?.findIndex((v) => v === item2.id)
                        : -1 >= 0
                ) {
                    itemRelation = new ItemRelation(item1.id, item2.id);
                } else if (
                    this.relations.has(item2.id)
                        ? this.relations
                              .get(item2.id)
                              ?.findIndex((v) => v === item1.id)
                        : -1 >= 0
                ) {
                    itemRelation = new ItemRelation(item2.id, item1.id);
                }
                const itemPair = new ItemPair(item1, item2, itemRelation);
                result.push(itemPair);
            }
            if (++i >= fromArray.length) {
                return [];
            }
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
