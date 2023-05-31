"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GraphService = void 0;
const common_1 = require("@nestjs/common");
const graph_1 = require("../models/graph");
const lodash_clonedeep_1 = __importDefault(require("lodash.clonedeep"));
let GraphService = class GraphService {
    isGraphCylicx(g) {
        const q = [];
        const map = new Map();
        const stack = new Set();
        const visited = new Set();
        let k = 0;
        console.log('start bfs', JSON.stringify(g));
        while (visited.size < g.size) {
            if (!visited.has(k)) {
                q.push(k);
                stack.add(k);
            }
            k++;
            while (q.length != 0) {
                const u = q[0];
                q.shift();
                visited.add(u);
                stack.delete(u);
                console.log('step', u);
                for (let i = 0; i < g.adj[u].length; i++) {
                    const next = g.adj[u][i];
                    console.log('next', next);
                    if (visited.has(next)) {
                        console.log('visited', next);
                        const result = [];
                        result.push(next);
                        result.push(u);
                        let n = u;
                        while (map.has(n) && map.get(n) != next) {
                            n = map.get(n);
                            result.push(n);
                        }
                        result.push(next);
                        return result.reverse();
                    }
                    else if (!stack.has(next)) {
                        q.push(next);
                        stack.add(next);
                        map.set(next, u);
                    }
                }
            }
        }
        return [];
    }
    isGraphCylic(g) {
        const visited = new Array(g.size);
        const recStack = new Array(g.size);
        for (let i = 0; i < g.size; i++) {
            visited[i] = false;
            recStack[i] = false;
        }
        for (let i = 0; i < g.size; i++) {
            const result = this.isGraphCylicUtill(g, i, visited, recStack);
            if (result.length > 0)
                return result.reverse();
        }
        return [];
    }
    feedbackArkSet(graph) {
        const w = new Array(graph.size);
        const g = new graph_1.Graph(graph.size);
        g.adj = (0, lodash_clonedeep_1.default)(graph.adj);
        const F = new graph_1.Graph(graph.size);
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
            if (e === undefined)
                e = 0;
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
            const adjElement = (0, lodash_clonedeep_1.default)(F.adj[i]);
            for (let j = 0; j < adjElement.length; j++) {
                g.addEdge(i, adjElement[j]);
                if (this.isGraphCylic(g).length > 0) {
                    g.removeEdge(i, adjElement[j]);
                }
                else {
                    F.removeEdge(i, adjElement[j]);
                }
            }
        }
        return F;
    }
    topologicalSortAcyclicGraph(g) {
        if (this.isGraphCylic(g).length > 0)
            throw new Error("Can't do topological sort for graph with cycles");
        const inDegree = new Array(g.size).fill(0);
        for (let u = 0; u < g.size; u++) {
            for (let i = 0; i < g.adj[u].length; i++) {
                inDegree[g.adj[u][i]]++;
            }
        }
        const s = new Set();
        for (let i = 0; i < g.size; i++) {
            if (inDegree[i] == 0)
                s.add(i);
        }
        let cnt = 0;
        const topOrderResult = [];
        while (s.size > 0) {
            const u = Array.from(s).sort()[0];
            s.delete(u);
            topOrderResult.push(u);
            for (let i = 0; i < g.adj[u].length; i++) {
                if (--inDegree[g.adj[u][i]] == 0)
                    s.add(g.adj[u][i]);
            }
            cnt++;
        }
        if (cnt != g.size) {
            throw new Error("Can't do topological sort for graph with cycles");
        }
        return topOrderResult;
    }
    topologicalSort(graph) {
        const g = new graph_1.Graph(graph.size);
        g.adj = (0, lodash_clonedeep_1.default)(graph.adj);
        const F = this.feedbackArkSet(graph);
        for (let i = 0; i < F.size; i++) {
            for (let j = 0; j < F.adj[i].length; j++) {
                g.removeEdge(i, F.adj[i][j]);
            }
        }
        return this.topologicalSortAcyclicGraph(g);
    }
    isGraphCylicUtill(g, i, visited, recStack) {
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
                            if (result[result.length - 1] === result[0])
                                return result;
                            else
                                return result.concat([i]);
                        }
                    }
                }
        }
        recStack[i] = false;
        return [];
    }
};
GraphService = __decorate([
    (0, common_1.Injectable)()
], GraphService);
exports.GraphService = GraphService;
//# sourceMappingURL=graph.service.js.map