import { Injectable } from '@nestjs/common';
import { Graph } from '../models/graph';

@Injectable()
export class GraphService {
    isGraphCylic(g: Graph): number[] {
        const visited: boolean[] = new Array<boolean>(g.size);
        const recStack: boolean[] = new Array<boolean>(g.size);
        for (let i = 0; i < g.size; i++) {
            visited[i] = false;
            recStack[i] = false;
        }
        for (let i = 0; i < g.size; i++) {
            const result = this.isGraphCylicUtill(g, i, visited, recStack);
            if (result.length > 0) return result.reverse();
        }
        return [];
    }

    private isGraphCylicUtill(
        g: Graph,
        i: number,
        visited: boolean[],
        recStack: boolean[],
    ): number[] {
        if (!visited[i]) {
            visited[i] = true;
            recStack[i] = true;
            const children = g.adj[i];
            if (children)
                for (let c = 0; c < children.length; c++) {
                    if (recStack[children[c]]) {
                        return [children[c], i];
                    }
                    if (!visited[children[c]]) {
                        const result = this.isGraphCylicUtill(
                            g,
                            children[c],
                            visited,
                            recStack,
                        );
                        if (result.length > 0) {
                            if (result[result.length - 1] === result[0])
                                return result;
                            else return result.concat([i]);
                        }
                    }
                }
        }
        recStack[i] = false;
        return [];
    }
}
