export class FunctionUtils {
    static compose<T, U, V>(f: (x: T) => U, g: (y: V) => T): (x: V) => U {
        return (x: V) => f(g(x));
    }
}
