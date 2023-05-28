import { Test, TestingModule } from '@nestjs/testing';
import { GraphService } from './graph.service';
import { Graph } from '../models/graph';

describe('GraphService', () => {
    let service: GraphService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [GraphService],
        }).compile();

        service = module.get<GraphService>(GraphService);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    it('detect cyclic graph', () => {
        const g: Graph = new Graph(4);
        g.addEdge(0, 1);
        g.addEdge(1, 2);
        g.addEdge(2, 3);
        g.addEdge(3, 1);

        expect(service.isGraphCylic(g)).toStrictEqual([1, 2, 3, 1]);
    });

    it('detect cyclic graph', () => {
        const g: Graph = new Graph(4);
        g.addEdge(0, 1);
        g.addEdge(0, 2);
        g.addEdge(1, 2);
        g.addEdge(2, 0);
        g.addEdge(2, 3);
        g.addEdge(3, 3);
        expect(service.isGraphCylic(g)).toStrictEqual([0, 1, 2, 0]);
    });

    it('detect cyclic graph', () => {
        const g: Graph = new Graph(8);
        g.addEdge(0, 1);
        g.addEdge(0, 2);
        g.addEdge(1, 3);
        g.addEdge(2, 3);
        g.addEdge(3, 4);
        g.addEdge(4, 2);
        g.addEdge(4, 5);
        g.addEdge(4, 6);
        g.addEdge(4, 7);
        g.addEdge(7, 8);
        expect(service.isGraphCylic(g)).toStrictEqual([3, 4, 2, 3]);
    });

    it('detect acyclic graph', () => {
        const g: Graph = new Graph(4);
        g.addEdge(0, 1);
        g.addEdge(0, 2);
        g.addEdge(1, 2);
        g.addEdge(2, 3);
        expect(service.isGraphCylic(g)).toStrictEqual([]);
    });

    it('detect cyclic graph', () => {
        const g: Graph = new Graph(8);
        g.addEdge(0, 1);
        g.addEdge(0, 2);
        g.addEdge(1, 3);
        g.addEdge(2, 3);
        g.addEdge(3, 4);
        g.addEdge(4, 5);
        g.addEdge(4, 6);
        g.addEdge(4, 7);
        g.addEdge(7, 8);

        expect(service.isGraphCylic(g)).toStrictEqual([]);
    });
});
