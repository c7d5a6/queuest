import { Injectable } from '@nestjs/common';
import { ItemEntity } from '../persistence/entities/item.entity';
import { Graph } from '../models/graph';
import { GraphService } from './graph.service';

@Injectable()
export class ItemsService {
    items: ItemEntity[] = [];
    relations: Map<number, number[]> = new Map<number, number[]>();

    constructor(private readonly graphService: GraphService) {
        this.items.push(new ItemEntity(1, 'The Godfather'));
        this.items.push(new ItemEntity(2, 'The Shawshank Redemption'));
        this.items.push(new ItemEntity(3, 'The Dark Knight'));
        this.items.push(new ItemEntity(4, 'Pulp Fiction'));
        this.items.push(new ItemEntity(5, 'Forrest Gump'));
        this.items.push(new ItemEntity(6, 'The Matrix'));
        this.items.push(
            new ItemEntity(7, 'Star Wars: Episode IV - A New Hope'),
        );
        this.items.push(new ItemEntity(8, 'The Silence of the Lambs'));
        this.items.push(
            new ItemEntity(
                9,
                'The Lord of the Rings: The Fellowship of the Ring',
            ),
        );
        this.items.push(new ItemEntity(10, 'Goodfellas'));
        this.items.push(new ItemEntity(11, 'The Social Network'));
        this.items.push(new ItemEntity(12, 'Parasite'));
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
