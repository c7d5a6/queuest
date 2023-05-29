import {Controller, Get, Post} from '@nestjs/common';
import { ItemsService } from '../services/items.service';
import { ItemEntity } from '../persistence/entities/item.entity';

@Controller('items')
export class ItemsController {
    constructor(private readonly itemsService: ItemsService) {}

    private static makeList(listData: ItemEntity[]): string {
        const listItems = listData.map(
            (item) => `<li key={${item.id}}>${item.name}</li>`,
        );

        return `<ol>${listItems.join('')}</ol>`;
    }

    @Get()
    getItems(): ItemEntity[] {
        const result = this.itemsService.getItemsSorted();
        return result;
    }
}
