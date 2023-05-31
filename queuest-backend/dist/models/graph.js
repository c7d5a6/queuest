"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Graph = void 0;
class Graph {
    constructor(v) {
        this.adj = [];
        this.v = v;
        for (let i = 0; i < v; i++)
            this.adj.push([]);
    }
    get size() {
        return this.v;
    }
    addEdge(s, d) {
        this.adj[s].push(d);
    }
    removeEdge(s, d) {
        const index = this.adj[s].indexOf(d, 0);
        if (index > -1)
            this.adj[s].splice(index, 1);
    }
}
exports.Graph = Graph;
//# sourceMappingURL=graph.js.map