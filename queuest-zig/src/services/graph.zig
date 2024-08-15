const std = @import("std");

const gsize = usize;

pub const Graph = struct {
    size: gsize,
    edges_size: usize,
    edges: []const std.ArrayListUnmanaged(gsize),
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
        try self.edges[f].append(self.a, t);
    }

    pub fn isCyclic(self: *const Graph) !bool {
        const a = self.a;
        const visited: []bool = try a.alloc(bool, self.size);
        @memset(visited, false);
        const stack = try std.ArrayListUnmanaged(gsize).initCapacity(a, self.size + self.edges_size);
        for (0..self.size) |i| {
            if (!visited[i]) stack.append(i);
            while (stack.getLastOrNull()) |v| {
                if (visited[i]) continue;
                visited[v] = true;
                for (self.edges[v].items) |w| {
                    stack.append(w);
                }
            }

            // if (cyclic) return true;
        }
        return false;
    }

    fn _isCyclic(self: *const Graph, i: usize, visited: []bool, r_stack: []bool) !bool {
        _ = self;
        _ = r_stack;
        // if(!visited.*.[i])
        visited[i] = true;
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
