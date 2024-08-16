import { Injectable } from '@nestjs/common';
import { Graph } from '../models/graph';
import cloneDeep from 'lodash.clonedeep';

@Injectable()
export class GraphService {

    isGraphCylic(g: Graph): number[] {
        const visited: boolean[] = new Array<boolean>(g.size);
        const recStack: boolean[] = new Array<boolean>(g.size);
        for (let i = 0; i < g.size; i++) {
            visited[i] = false;
            recStack[i] = false;
        }
        for (let i = 0; i < g.size; i++) {
            const result = this.isGraphCylicUtill(g, i, visited, recStack);
            if (result.length > 0) return result.reverse();
        }
        return [];
    }

    feedbackArkSet(graph: Graph): Graph {
        const w: number[][] = new Array(graph.size);
        const g: Graph = new Graph(graph.size);
        g.adj = cloneDeep(graph.adj);
        const F = new Graph(graph.size);
        let cycle = this.isGraphCylic(g);
        while (cycle.length > 0) {
            let e = undefined;
            for (let i = 0; i < cycle.length - 1; i++) {
                const a = cycle[i];
                const b = cycle[i + 1];
                if (w[a] === undefined) {
                    w[a] = new Array(graph.size);
                }
                if (w[a][b] === undefined) {
                    w[a][b] = graph.size + 1 - graph.adj[a].length;
                }
                e = e === undefined ? w[a][b] : Math.min(e, w[a][b]);
            }
            if (e === undefined) e = 0;
            for (let i = 0; i < cycle.length - 1; i++) {
                const a = cycle[i];
                const b = cycle[i + 1];
                w[a][b] = w[a][b] - e;
                if (w[a][b] <= 0) {
                    g.removeEdge(a, b);
                    F.addEdge(a, b);
                }
            }
            cycle = this.isGraphCylic(g);
        }
        for (let i = 0; i < F.size; i++) {
            const adjElement = cloneDeep(F.adj[i]);
            for (let j = 0; j < adjElement.length; j++) {
                g.addEdge(i, adjElement[j]);
                if (this.isGraphCylic(g).length > 0) {
                    g.removeEdge(i, adjElement[j]);
                } else {
                    F.removeEdge(i, adjElement[j]);
                }
            }
        }
        return F;
    }

    topologicalSortAcyclicGraph(g: Graph): number[] {
        if (this.isGraphCylic(g).length > 0) throw new Error("Can't do topological sort for graph with cycles");
        const inDegree: number[] = new Array(g.size).fill(0);
        for (let u = 0; u < g.size; u++) {
            for (let i = 0; i < g.adj[u].length; i++) {
                inDegree[g.adj[u][i]]++;
            }
        }
        const s = new Set<number>();
        for (let i = 0; i < g.size; i++) {
            if (inDegree[i] == 0) s.add(i);
        }
        let cnt = 0;
        const topOrderResult = [];
        while (s.size > 0) {
            const u: number = Array.from(s).sort()[0];
            s.delete(u);
            topOrderResult.push(u);
            for (let i = 0; i < g.adj[u].length; i++) {
                if (--inDegree[g.adj[u][i]] == 0) s.add(g.adj[u][i]);
            }
            cnt++;
        }
        if (cnt != g.size) {
            throw new Error("Can't do topological sort for graph with cycles");
        }
        return topOrderResult;
    }

    topologicalSort(graph: Graph): number[] {
        const g: Graph = new Graph(graph.size);
        g.adj = cloneDeep(graph.adj);
        const F = this.feedbackArkSet(graph);
        for (let i = 0; i < F.size; i++) {
            for (let j = 0; j < F.adj[i].length; j++) {
                g.removeEdge(i, F.adj[i][j]);
            }
        }
        return this.topologicalSortAcyclicGraph(g);
    }

    private isGraphCylicUtill(g: Graph, i: number, visited: boolean[], recStack: boolean[]): number[] {
        if (!visited[i]) {
            visited[i] = true;
            recStack[i] = true;
            const children = g.adj[i];
            if (children)
                for (let c = 0; c < children.length; c++) {
                    if (recStack[children[c]]) {
                        return [children[c], i];
                    }
                    if (!visited[children[c]]) {
                        const result = this.isGraphCylicUtill(g, children[c], visited, recStack);
                        if (result.length > 0) {
                            if (result[result.length - 1] === result[0]) return result;
                            else return result.concat([i]);
                        }
                    }
                }
        }
        recStack[i] = false;
        return [];
    }
}
