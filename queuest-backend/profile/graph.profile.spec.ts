import { Test, TestingModule } from '@nestjs/testing';
import { GraphService } from '../src/services/graph.service';
import { Graph } from '../src/models/graph';
import { FunctionUtils } from '../src/utils/function.utils';

const MAX_SIZE = 1_000_000_00;

function createGraph(n: number, del: number): Graph {
    const graph = new Graph(n);
    for (let i = 0; i < n; i++) {
        for (let j = 0; j < n; j++) {
            if (i != j) {
                const cbr = FunctionUtils.cyrb53a(i, j);
                if (cbr % del === 0) {
                    graph.addEdge(i, j);
                }
            }
        }
    }
    return graph;
}

describe('GraphService', () => {
    let service: GraphService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [GraphService],
        }).compile();
        service = module.get<GraphService>(GraphService);
    });

    // it('detect cyclic graph', () => {
    //     expect(service.isGraphCylic(graph)).toBeDefined();
    // });
    //
    it('detect is', () => {
        for (var n = 1; n < 2000; n = n * 2) {
            var times = MAX_SIZE / (n * n * n * n);
            var t = 0;
            var create = Date.now();
            for (var del = 2; del < n; del++) {
                const graph = createGraph(n, del);
                var date = Date.now();
                for (var i = 0; i < Math.max(1000, times); i++) {
                    expect(service.isGraphCylic(graph).length >= 0).toBeTruthy();
                }
                t += Date.now() - date;
            }
            console.log(`Time for ${n} size created ${Date.now() - create - t} times ${Math.max(1000, times)} in ms: ${t}`);
        }
    });

    // it('detect cyclic graph', () => {
    //     const initialArcs = graph.adj.flat();
    //     const arcSet = service.feedbackArkSet(graph);
    //     const arcs = arcSet.adj.flat();
    //     console.log(
    //         'ARC LENGTH',
    //         initialArcs.length,
    //         'FEEDBACK LENGTH',
    //         arcs.length,
    //     );
    //     expect(arcs.length).toBeGreaterThan(0);
    // });

    // it('sort cyclic graph', () => {
    //     const sort = service.topologicalSort(graph);
    //     expect(sort.length).toBe(size);
    // });
});
