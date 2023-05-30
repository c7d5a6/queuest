import { ApiProperty } from '@nestjs/swagger';

export class ItemRelation {
    @ApiProperty()
    from: number;
    @ApiProperty()
    to: number;

    constructor(from: number, to: number) {
        this.from = from;
        this.to = to;
    }
}
