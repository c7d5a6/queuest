import { Options } from './options';
/**
 * Represents a possible enumerated value
 */
export declare class EnumValue {
    type: string;
    options: Options;
    name: string;
    value: string;
    description: string;
    constructor(type: string, name: string | undefined, description: string | undefined, _value: any, options: Options);
}
