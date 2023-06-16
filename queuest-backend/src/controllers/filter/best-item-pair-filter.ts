import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsInt, IsNumber } from 'class-validator';
import { Transform } from 'class-transformer';

export class BestItemPairFilter {
    @ApiProperty({
        minimum: 0,
        maximum: 10000,
        title: 'Page',
        exclusiveMaximum: true,
        exclusiveMinimum: true,
        format: 'int32',
        default: 0,
    })
    page: number;

    @IsArray()
    @IsInt({ each: true })
    @Transform(({ value }) =>
        value
            .trim()
            .split(',')
            .map((id: any) => Number(id)),
    )
    @ApiProperty({ type: [Number] })
    exclude: number[];
}
