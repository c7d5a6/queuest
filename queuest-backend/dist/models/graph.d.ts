export declare class Graph {
    private v;
    adj: number[][];
    constructor(v: number);
    get size(): number;
    addEdge(s: number, d: number): void;
    removeEdge(s: number, d: number): void;
}
