import { Graph } from '../models/graph';
export declare class GraphService {
    isGraphCylicx(g: Graph): number[];
    isGraphCylic(g: Graph): number[];
    feedbackArkSet(graph: Graph): Graph;
    topologicalSortAcyclicGraph(g: Graph): number[];
    topologicalSort(graph: Graph): number[];
    private isGraphCylicUtill;
}
