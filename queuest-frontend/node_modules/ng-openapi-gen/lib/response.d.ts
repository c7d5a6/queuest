import { Content } from './content';
import { Options } from './options';
/**
 * An operation response
 */
export declare class Response {
    statusCode: string;
    description: string;
    content: Content[];
    options: Options;
    constructor(statusCode: string, description: string, content: Content[], options: Options);
}
