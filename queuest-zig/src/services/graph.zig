const std = @import("std");
const ArrayLU = std.ArrayListUnmanaged(gsize);

const gsize = usize;

pub const Graph = struct {
    size: gsize,
    edges_size: gsize,
    edges: []ArrayLU,
    a: std.mem.Allocator,

    pub fn init(a: std.mem.Allocator, size: gsize) Graph {
        const edge_size_init = if (size > 0) std.math.log2(size) + 2 else 0;
        const e = a.alloc(ArrayLU, size) catch unreachable;
        for (0..size) |i| {
            e[i] = ArrayLU.initCapacity(a, edge_size_init) catch unreachable;
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

    pub fn isCyclic(self: *const Graph) !?ArrayLU {
        const a = self.a;
        const visited: []bool = try a.alloc(bool, self.size);
        @memset(visited, false);
        var stack = try ArrayLU.initCapacity(a, self.size + self.edges_size);
        const in_stack: []bool = try a.alloc(bool, self.size);
        @memset(in_stack, false);
        const from: []gsize = try a.alloc(gsize, self.size);
        var i: gsize = 0;
        while (i < self.size) : (i += 1) {
            // for (0..self.size) |i| {
            if (!visited[i]) try stack.append(a, i);
            while (stack.getLastOrNull()) |v| {
                in_stack[v] = true;
                var added = false;
                for (self.edges[v].items) |w| {
                    if (in_stack[w]) {
                        var result = try ArrayLU.initCapacity(a, stack.items.len);
                        try result.append(a, w);
                        from[w] = v;
                        while (result.getLastOrNull()) |next| {
                            try result.append(a, from[next]);
                            if (from[next] == w) {
                                break;
                            }
                        }
                        return result;
                    }
                    if (!visited[w]) {
                        try stack.append(a, w);
                        from[w] = v;
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
        return null;
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
    try expect(try g.isCyclic() == null);

    g.addEdge(4, 2);
    const cycle = try g.isCyclic();
    try expect(cycle != null);
    std.debug.print("Cycle {any}", .{cycle.?.items});
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

    var i: gsize = 0;
    while (i < size) : (i += 1) {
        var j: gsize = 0;
        while (j < size) : (j += 1) {
            if (cyrb53a(i, j) % 11 == 0) {
                g.addEdge(i, j);
            }
        }
    }
    std.debug.print("\nTime to init: {d}\n", .{std.time.microTimestamp() - mil});

    const mili = std.time.microTimestamp();
    for (0..1000) |ii| {
        _ = ii;
        try expect(try g.isCyclic() != null);
    }
    std.debug.print("\nTime cyclic: {d}\n", .{std.time.microTimestamp() - mili});
}

const MAX_SIZE = 1_000_000_00;
// var create = Date.now();
// for (var del = 2; del < n; del++) {
//     const graph = createGraph(n, del);
//     var date = Date.now();
//     for (var i = 0; i < Math.max(1000, times); i++) {
//         expect(service.isGraphCylic(graph).length >= 0).toBeTruthy();
//     }
//     t += Date.now() - date;
// }
// console.log(`Time for ${n} size created ${Date.now() - create - t} times ${Math.max(1000, times)} in ms: ${t}`);

test "cyclic test" {
    const ca = std.heap.c_allocator;
    var arena = std.heap.ArenaAllocator.init(ca);
    var n: gsize = 2;
    while (n < 2000) {
        const nn: usize = @intCast(n);
        var times: usize = MAX_SIZE / (nn * nn * nn * nn);
        times = if (times < 1000) 1000 else times;
        var t: i64 = 0;
        const create = std.time.microTimestamp();
        var del: gsize = 1;
        while (del < n) : (del += 1) {
            // for (2..n) |del| {
            var graph = createGraph(arena.allocator(), n, del);
            defer _ = arena.reset(.retain_capacity);
            const date = std.time.microTimestamp();
            for (0..times) |i| {
                _ = i;
                const tt = try graph.isCyclic();
                try expect(tt == null or tt.?.items.len >= 0);
            }
            t += std.time.microTimestamp() - date;
        }
        std.debug.print("\nTime for {d} size created {d} times {d} in ms: {d}", .{ n, std.time.microTimestamp() - create - t, times, t });
        n *= 2;
    }
}

fn createGraph(a: std.mem.Allocator, size: gsize, del: gsize) Graph {
    var g: Graph = Graph.init(a, size);
    var i: gsize = 0;
    while (i < size) : (i += 1) {
        var j: gsize = 0;
        while (j < size) : (j += 1) {
            if (cyrb53a(i, j) % del == 0) {
                g.addEdge(i, j);
            }
        }
    }
    return g;
}

fn cyrb53a(ii: gsize, jj: gsize) usize {
    const i: usize = @intCast(ii);
    const j: usize = @intCast(jj);
    var h1 = 0xdeadbeef ^ i * 2654435761;
    var h2 = 0x41c6ce57 ^ j * 1597334677;
    h1 ^= h1 ^ (h2 >> 15) * 0x735a2d97;
    h2 ^= h2 ^ (h1 >> 15) * 0xcaf649a9;
    h1 ^= h2 >> 16;
    h2 ^= h1 >> 16;
    return 2097152 * (h2 >> 0) + (h1 >> 11);
}
