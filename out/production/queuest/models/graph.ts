export class Graph {
    private v;
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

    removeEdge(s: number, d: number) {
        const index = this.adj[s].indexOf(d, 0);
        if (index > -1) this.adj[s].splice(index, 1);
    }
}
