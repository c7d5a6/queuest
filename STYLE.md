# Zig Style

Design goals, in order: **safety**, **performance**, **developer experience**, **Zen**.

## Zen

- Communicate intent precisely.
- Edge cases matter.
- Favor reading code over writing code.
- There is an idiomatic way to do it.
- Runtime crashes are better than bugs.
- Compile errors are better than runtime crashes.
- Incremental improvements.
- Avoid local maximums.
- Reduce the amount one must remember.
- Focus on logic, not style.
- Resource allocation may fail.
- Resource deallocation must succeed.
- Together, we serve the users.

## Shared

- Run `zig fmt`.
- 4-space indent. Open braces on the same line unless the header wraps.
- Hard limit: 100 columns. Wrap with a trailing comma and let `zig fmt` finish.
- Braces on `if` unless the whole statement fits on one line.
- Source is UTF-8, LF line endings, no BOM, no other control characters.
- Comments explain **why** (and how, when that is not obvious). Code is not documentation.
- Comments are sentences: space after `//`, capital letter, period. End-of-line comments may be phrases.
- If a list has more than two items, one item per line, trailing comma.

## Zig

These conventions are not enforced by the compiler.

### Names

- Types and type aliases: `TitleCase`.
- Functions: `camelCase`. Functions that return `type`: `TitleCase`.
- Variables, parameters, namespaces (empty struct, never instantiated): `snake_case`.
- Acronyms follow those rules as words: `XmlParser`, `readU32Be`, not `XMLParser` / `readU32BE`.
- Type files (`struct` with fields): `TitleCase.zig`. Namespace files: `snake_case.zig`. Directories: `snake_case`.
- Established names (`ENOENT`) stay as they are.

Do not use `Value`, `Data`, `Context`, `Manager`, `State`, `utils`, `misc`, or initials in type names. They name nothing.

Name from the fully-qualified path. Do not repeat a segment: `json.JsonValue` → `json.Value` (the file or parent is already `json`).

No underscore prefixes. Zig has no private fields; do not fake them. For keyword collisions use `@"name"`. Prefer longer names in outer scopes, shorter in inner scopes.

A function with two `u64` arguments, or any nullable argument whose `null` meaning is unclear at the call site, takes an options struct.

```zig
const ns = @import("dir/file.zig");
const TypeName = @import("dir/TypeName.zig");

fn functionName(param_name: TypeName) void {}

fn ShortList(comptime T: type, comptime n: usize) type {
    return struct { items: [n]T };
}

fn readU32Be() u32 {}
```

### Doc comments

- Do not repeat what the name already says.
- Duplicate help text across similar functions; tools show it per symbol.
- **assume**: invariant; violation is unchecked illegal behavior.
- **assert**: invariant; violation is safety-checked illegal behavior.

## Safety

- Simple, explicit control flow. Recursion only with a hard depth or size limit.
- Bound everything (loops, queues). Fail fast when a bound is hit. An event loop that must not stop is asserted as such.
- Prefer explicit widths (`u32`). Avoid `usize` except for lengths and indexes that must match std (slices, allocators).
- Smallest scope for each variable. Few variables in scope.
- Soft limit: 70 lines per function. Parent owns control flow and state (`if`/`switch`). Helpers compute; keep them branch-light and pure. Push `if`s up, `for`s down.
- Treat compiler warnings as errors at the strictest setting.
- Do not run logic directly off external events. The program advances at its own pace so you can batch and bound work per period.
- Handle every error.
- Pass library options at the call site. Do not rely on defaults: `@prefetch(a, .{ .cache = .data, .rw = .read, .locality = 3 })`.

### Assertions

Assertions catch programmer errors. Operating errors are handled. A failed assertion is a crash: corrupt code has no recovery. That turns correctness bugs into liveness bugs and makes fuzzing useful.

- Assert arguments, returns, pre/postconditions, and invariants. Do not run on unchecked data. Average at least two assertions per function.
- Pair them: the same property on two paths (e.g. before write and after read).
- Split: `assert(a); assert(b);` not `assert(a and b);`.
- Implication: `if (a) assert(b);`.
- Assert relations of comptime constants (layout, sizes, design invariants).
- Assert the valid space **and** the invalid space. Tests cover both, and the boundary.
- Build the mental model first, encode it in assertions, then test. Tests show bugs exist; they do not prove absence.

### Conditions

Split compound booleans into nested `if`/`else`. Prefer `else { if { } }` over long `else if` chains. If there is a positive branch, handle or assert the negative.

State invariants in the positive form:

```zig
if (index < count) {
    // holds
} else {
    // does not
}
```

Avoid `index >= count` as the happy-path test.

## Performance

- Choose the design for performance first. Measurement comes after; the large wins are in the sketch.
- Sketch network, disk, memory, CPU × bandwidth and latency. Land near the global maximum, not a local one.
- Optimize the slowest resource first (network, disk, memory, CPU), adjusted for how often it is used.
- Keep control plane and data plane separate. Batch on the data plane so assertions stay cheap.
- Batch access to network, disk, memory, and CPU. Give the CPU large, predictable chunks of work.
- Do not depend on the compiler to save you. Extract hot loops into functions with primitive arguments and no `self`, so registers and redundant work are obvious.

## Locals and copies

- Do not alias or duplicate variables. State will drift.
- If a value must not be copied and the type is larger than 16 bytes, pass `*const`.
- Return structs by value. Use an out-pointer only when a copy is a real problem.
- Introduce a variable at the point of use. Drop it when it is done. Check close to use.
- Prefer the simplest return that works: `void` > `bool` > `u64` > `?u64` > `!u64`. Dimensionality at the call site spreads.
- Functions with assertions should run to completion (no suspend) so those assertions stay true for the whole call.
- Zero unused buffer padding. Partial fills leak and break determinism.
- Blank line before an allocation and after its `defer`, so leaks are visible.

## Off-by-one

`index` is 0-based, `count` is 1-based, `size` is `count` times the unit. Put the unit in the name.

Show division intent: `@divExact`, `@divFloor`, or `div_ceil`.

## Dependencies

Minimize dependencies. Each one needs a concrete reason. Prefer the Zig toolchain.

## Tooling

Prefer `scripts/*.zig` over shell. Zig scripts are typed and portable. Keep the toolbox small.
