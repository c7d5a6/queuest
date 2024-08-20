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

    pub fn removeEdge(self: *Graph, f: gsize, t: gsize) void {
        for (self.edges[f].items, 0..) |to, i| {
            if (to == t) {
                _ = self.edges[f].swapRemove(i);
                self.edges_size -= 1;
                return;
            }
        }
    }

    pub fn clone(self: *const Graph, a: std.mem.Allocator) !Graph {
        var g: Graph = Graph.init(a, self.size);
        for (0..self.size) |i| {
            g.edges[i] = try self.edges[i].clone(a);
        }
        return g;
    }

    fn reverse(items: *[]gsize) void {
        var tmp: gsize = undefined;
        for (0..items.*.len / 2) |i| {
            tmp = items.*[i];
            items.*[i] = items.*[items.len - 1 - i];
            items.*[items.len - 1 - i] = tmp;
        }
    }

    pub fn getCycle(self: *const Graph) !?[]gsize {
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
                        reverse(&result.items);
                        return result.items;
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

    fn feedbackArk(self: *const Graph) !Graph {
        var weight: []?std.AutoHashMap(gsize, isize) = undefined;
        weight = try self.a.alloc(?std.AutoHashMap(gsize, isize), self.size);
        var g: Graph = try self.clone(self.a); // Clone deep;
        var feedback: Graph = Graph.init(self.a, self.size);

        while (try g.getCycle()) |cycle| {
            var e: ?gsize = null;
            for (0..cycle.len - 1) |i| {
                const f = cycle[i];
                const t = cycle[i + 1];
                if (weight[f] == null)
                    weight[f] = std.AutoHashMap(gsize, isize).init(self.a);
                if (weight[f].?.get(t) == null) {
                    try weight[f].?.put(t, @intCast(self.size + 1 - self.edges[f].items.len));
                }
                if (weight[f].?.get(t)) |w| {
                    if (e == null or w < e.?)
                        e = @intCast(w);
                }
            }
            if (e == null) e = 0;
            for (0..cycle.len - 1) |i| {
                const f = cycle[i];
                const t = cycle[i + 1];
                if (weight[f].?.get(t)) |w| {
                    var nw: isize = @intCast(w);
                    nw -= @intCast(e.?);
                    try weight[f].?.put(t, nw);
                    if (nw <= 0) {
                        g.removeEdge(f, t);
                        feedback.addEdge(f, t);
                    }
                }
            }
        }

        for (0..g.size) |f| {
            if (feedback.edges[f].items.len == 0)
                continue;
            const eds = try feedback.edges[f].clone(self.a);
            for (eds.items) |t| {
                g.addEdge(f, t);
                if (try g.getCycle()) |_| {
                    g.removeEdge(f, t);
                } else {
                    feedback.removeEdge(f, t);
                }
            }
        }

        return feedback;
    }
};

fn printEdges(g: Graph) void {
    for (0..g.size) |f| {
        for (g.edges[f].items) |t| {
            std.debug.print("\t({d} -> {d})\n", .{ f, t });
        }
    }
}

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
    try expect(try g.getCycle() == null);

    g.addEdge(4, 2);
    const cycle = try g.getCycle();
    try expect(cycle != null);
    std.debug.print("Cycle {any}\n", .{cycle});

    const ark = try g.feedbackArk();
    std.debug.print("Ark:\n", .{});
    printEdges(ark);
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
        try expect(try g.getCycle() != null);
    }
    std.debug.print("\nTime cyclic: {d}\n", .{std.time.microTimestamp() - mili});
}

const MAX_SIZE = 1_000_000;
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
//

test "cyclic test" {
    std.debug.print("\n", .{});
    const ca = std.heap.c_allocator;
    var arena = std.heap.ArenaAllocator.init(ca);
    var n: gsize = 2;
    while (n < 11560) {
        const nn: usize = @intCast(n);
        var times: usize = MAX_SIZE / (nn * nn * nn * nn);
        times = if (times < 1000) 1000 else times;
        times = 2;
        var t: i64 = 0;
        const create = std.time.microTimestamp();
        var del: gsize = 1;
        while (del < n) : (del += 1) {
            // for (2..n) |del| {
            var graph = createGraph(arena.allocator(), n, del);
            defer _ = arena.reset(.retain_capacity);
            const date = std.time.microTimestamp();
            for (0..times) |i| {
                if (i == 1 and del == 1) {
                    const as = arena.queryCapacity();
                    const out: struct { t: []const u8, s: usize } =
                        if (as < 1024)
                        .{ .t = "b", .s = as }
                    else if (as < 1024 * 1024)
                        .{ .t = "Kb", .s = (as / 1024) }
                    else
                        .{ .t = "Mb", .s = (as / 1024 / 1024) };

                    std.debug.print("\tFor graph({d}) Size of allocated mem: {d}{s}\n", .{ graph.size, out.s, out.t });
                }
                const tt = try graph.getCycle();
                try expect(tt == null or tt.?.len >= 0);
            }
            t += std.time.microTimestamp() - date;
        }
        std.debug.print("Time for {d} size created {d} times {d} in ms: {d}\n", .{ n, std.time.microTimestamp() - create - t, times, t });
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
