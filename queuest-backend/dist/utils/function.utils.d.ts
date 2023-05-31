export declare class FunctionUtils {
    static compose<T, U, V>(f: (x: T) => U, g: (y: V) => T): (x: V) => U;
    static cyrb53a(i: number, j: number): number;
}
