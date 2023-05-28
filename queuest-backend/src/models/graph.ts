export class Graph {
    private readonly v;
    adj: number[][] = [];

    constructor(v: number) {
        this.v = v;
        for (let i = 0; i < v; i++) this.adj.push([]);
    }

    get size() {
        return this.v;
    }

    addEdge(s: number, d: number) {
        this.adj[s].push(d);
    }
}
