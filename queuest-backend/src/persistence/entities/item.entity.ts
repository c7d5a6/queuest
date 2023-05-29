import {ApiProperty} from "@nestjs/swagger";

export class ItemEntity {

    @ApiProperty()
    id: number;

    @ApiProperty()
    name: string;

    constructor(id: number, name: string) {
        this.id = id;
        this.name = name;
    }
}
