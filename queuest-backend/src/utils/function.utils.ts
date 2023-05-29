export class FunctionUtils {
    static compose<T, U, V>(f: (x: T) => U, g: (y: V) => T): (x: V) => U {
        return (x: V) => f(g(x));
    }

    static cyrb53a(i: number, j: number): number {
        let h1 = Math.imul(0xdeadbeef ^ i, 2654435761);
        let h2 = Math.imul(0x41c6ce57 ^ j, 1597334677);
        h1 ^= Math.imul(h1 ^ (h2 >>> 15), 0x735a2d97);
        h2 ^= Math.imul(h2 ^ (h1 >>> 15), 0xcaf649a9);
        h1 ^= h2 >>> 16;
        h2 ^= h1 >>> 16;
        return 2097152 * (h2 >>> 0) + (h1 >>> 11);
    }
}
