const std = @import("std");

const gsize = usize;

pub const Graph = struct {
    size: gsize,
    edges_size: usize,
    edges: []std.ArrayListUnmanaged(gsize),
    a: std.mem.Allocator,

    pub fn init(a: std.mem.Allocator, size: gsize) Graph {
        const edge_size_init = if (size > 0) std.math.log2(size) + 2 else 0;
        const e = a.alloc(std.ArrayListUnmanaged(gsize), size) catch unreachable;
        for (0..size) |i| {
            e[i] = std.ArrayListUnmanaged(gsize).initCapacity(a, edge_size_init) catch unreachable;
        }
        return Graph{
            .size = size,
            .edges_size = 0,
            .edges = e,
            .a = a,
        };
    }

    const Edge = packed struct { from: gsize, to: gsize };
    pub fn addEdges(self: *Graph, edges: []const Edge) void {
        for (edges) |e| {
            self.addEdge(e.from, e.to);
        }
    }

    pub fn addEdge(self: *Graph, f: gsize, t: gsize) void {
        self.edges_size += 1;
        self.edges[f].append(self.a, t) catch unreachable;
    }

    pub fn isCyclic(self: *const Graph) !bool {
        const a = self.a;
        const visited: []bool = try a.alloc(bool, self.size);
        @memset(visited, false);
        var stack = try std.ArrayListUnmanaged(gsize).initCapacity(a, self.size + self.edges_size);
        const in_stack: []bool = try a.alloc(bool, self.size);
        @memset(in_stack, false);
        for (0..self.size) |i| {
            if (!visited[i]) try stack.append(a, i);
            while (stack.getLastOrNull()) |v| {
                in_stack[v] = true;
                var added = false;
                for (self.edges[v].items) |w| {
                    if (in_stack[w]) return true;
                    if (!visited[w]) {
                        try stack.append(a, w);
                        added = true;
                    }
                }
                if (!added) {
                    const vv = stack.pop();
                    in_stack[vv] = false;
                    visited[vv] = true;
                }
            }
        }
        return false;
    }
};

const expect = std.testing.expect;

test "create graph" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const a = gpa.allocator();
    const g: Graph = Graph.init(a, 10);

    try expect(g.edges.len == 10);
    // (log2 10 = 3.3) + 2 = 5
    try expect(g.edges[0].capacity == 5);
}

test "is cyclic" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const a = gpa.allocator();
    var g: Graph = Graph.init(a, 9);

    g.addEdge(1, 2);
    g.addEdge(1, 5);
    g.addEdge(1, 8);
    g.addEdge(2, 3);
    g.addEdge(3, 4);
    // g.addEdge(4, 2);
    g.addEdge(5, 6);
    g.addEdge(6, 3);
    g.addEdge(6, 7);
    g.addEdge(6, 8);

    try expect(g.edges.len == 9);
    try expect(try g.isCyclic() == false);

    g.addEdge(4, 2);
    try expect(try g.isCyclic() == true);
}

test "cyclic 500" {
    // var gpa = std.heap.GeneralPurposeAllocator(.{
    //     .thread_safe = true,
    // }){};
    // const a = gpa.allocator();
    const a = std.heap.c_allocator;
    const size = 500;
    const mil = std.time.microTimestamp();
    var g: Graph = Graph.init(a, size);

    for (0..size) |i| {
        for (0..size) |j| {
            if ((i * 3 + j) % 11 == 0) {
                g.addEdge(i, j);
            }
        }
    }
    std.debug.print("\nTime to init: {d}\n", .{std.time.microTimestamp() - mil});

    const mili = std.time.microTimestamp();
    for (0..1000) |i| {
        _ = i;
        try expect(try g.isCyclic() == true);
    }
    std.debug.print("\nTime cyclic: {d}\n", .{std.time.microTimestamp() - mili});
}
