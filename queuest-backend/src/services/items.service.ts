import { Injectable } from '@nestjs/common';
import { ItemEntity } from '../persistence/entities/item.entity';
import { Graph } from '../models/graph';
import { GraphService } from './graph.service';
import { ItemRelation } from '../models/item-relation';

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
        if (this.relations.has(relation.to)) {
            const index = this.relations
                .get(relation.to)
                ?.findIndex((value) => value == relation.from);
            if ((index || index === 0) && index > -1) this.relations.get(relation.to)?.splice(index, 1);
        }
        if (!this.relations.has(relation.from)) {
            this.relations.set(relation.from, []);
        }
        const index = this.relations
            .get(relation.from)
            ?.findIndex((value) => value == relation.to);
        if (index == -1) this.relations.get(relation.from)?.push(relation.to);
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
