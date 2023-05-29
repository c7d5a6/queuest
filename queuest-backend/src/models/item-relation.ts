import {ApiProperty} from "@nestjs/swagger";

export class ItemRelation {
    @ApiProperty()
    from: number;
    @ApiProperty()
    to: number;
}
