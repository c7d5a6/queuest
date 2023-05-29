import {Body, Controller, Get, Post} from '@nestjs/common';
import { ItemsService } from '../services/items.service';
import { ItemEntity } from '../persistence/entities/item.entity';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import {ItemRelation} from "../models/item-relation";

@ApiTags('Items')
@Controller('items')
export class ItemsController {
    constructor(private readonly itemsService: ItemsService) {}

    @Get()
    @ApiOkResponse({ description: 'Sorted items', type: [ItemEntity] })
    getItems(): ItemEntity[] {
        const result = this.itemsService.getItemsSorted();
        return result;
    }

    @Post()
    addItem(@Body() item: ItemEntity) {
        this.itemsService.addItem(item);
    }

    @Post('relation')
    addRelation(@Body() relation: ItemRelation) {
        this.itemsService.addRelation(relation);
    }
}
