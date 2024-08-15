import { Test, TestingModule } from '@nestjs/testing';
import { GraphService } from '../src/services/graph.service';
import { Graph } from '../src/models/graph';
import { FunctionUtils } from '../src/utils/function.utils';

describe('GraphService', () => {
    let service: GraphService;
    let graph: Graph;
    const size = 500;

    beforeAll(() => {
        graph = new Graph(size);
        const d0 = new Date();
        for (let i = 0; i < size; i++) {
            for (let j = 0; j < size; j++) {
                if (i != j) {
                    // const cbr = FunctionUtils.cyrb53a(i, j);
                    const cbr = (i * 3 + j);
                    if (cbr % 11 === 0) {
                        const cbrRev = FunctionUtils.cyrb53a(j, i);
                        if ((j < i && cbrRev % 2 !== 0) || i < j)
                            graph.addEdge(i, j);
                    }
                }
            }
        }
        const d1 = new Date();
        console.log(`Initial Time Cost: ${d1.getTime() - d0.getTime()} ms`);
    });

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [GraphService],
        }).compile();
        service = module.get<GraphService>(GraphService);
    });

    it('detect cyclic graph', () => {
        expect(service.isGraphCylic(graph)).toBeDefined();
    });

    it('detect is', () => {
        var t = Date.now();
        for (var i = 0; i < 1000; i++) {
            expect(service.isGraphCylic(graph).length > 0).toBeTruthy();
        }
        console.log("Time in ms:", (Date.now() - t));
    });

    xit('detect cyclic graph', () => {
        const initialArcs = graph.adj.flat();
        const arcSet = service.feedbackArkSet(graph);
        const arcs = arcSet.adj.flat();
        console.log(
            'ARC LENGTH',
            initialArcs.length,
            'FEEDBACK LENGTH',
            arcs.length,
        );
        expect(arcs.length).toBeGreaterThan(0);
    });

    xit('sort cyclic graph', () => {
        const sort = service.topologicalSort(graph);
        expect(sort.length).toBe(size);
    });
});
