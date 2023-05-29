import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { Graph } from './models/graph';
import { GraphService } from './services/graph.service';

@Controller()
export class AppController {
    constructor(
        private readonly appService: AppService,
        private readonly graphService: GraphService,
    ) {}

    private static makeList(listData: string[]): string {
        const listItems = listData.map(
            (item) => `<li key={${item}}>${item}</li>`,
        );

        return `<ol>${listItems.join('')}</ol>`;
    }

    @Get()
    getHello(): string {
        const movieList: string[] = [
            'The Godfather', // 0
            'The Shawshank Redemption', // 1
            'The Dark Knight', // 2
            'Pulp Fiction', // 3
            'Forrest Gump', // 4
            'The Matrix', // 5
            'Star Wars: Episode IV - A New Hope', // 6
            'The Silence of the Lambs', // 7
            'The Lord of the Rings: The Fellowship of the Ring', // 8
            'Goodfellas', // 9
            'The Social Network', // 10
            'Parasite', // 11
        ];
        const numbers = this.list();
        const result = [];
        for (let i = 0; i < numbers.length; i++) {
            result.push(movieList[numbers[i]]);
        }
        return AppController.makeList(result);
    }

    private list(): number[] {
        const graph: Graph = new Graph(12);
        graph.addEdge(1, 10);
        graph.addEdge(1, 3);
        graph.addEdge(1, 4);
        graph.addEdge(2, 0);
        graph.addEdge(2, 10);
        graph.addEdge(2, 11);
        graph.addEdge(3, 5);
        graph.addEdge(5, 0);
        graph.addEdge(5, 1);
        graph.addEdge(5, 10);
        graph.addEdge(5, 9);
        graph.addEdge(6, 2);
        graph.addEdge(6, 4);
        graph.addEdge(7, 3);
        graph.addEdge(7, 6);
        graph.addEdge(7, 9);
        graph.addEdge(8, 0);
        graph.addEdge(8, 3);
        graph.addEdge(8, 5);
        graph.addEdge(8, 7);
        graph.addEdge(8, 9);
        graph.addEdge(8, 1);
        graph.addEdge(11, 10);
        graph.addEdge(11, 4);
        console.log(this.graphService.isGraphCylic(graph));
        return this.graphService.topologicalSort(graph);
    }
}
