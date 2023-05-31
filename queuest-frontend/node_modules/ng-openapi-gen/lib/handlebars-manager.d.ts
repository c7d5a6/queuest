import * as Handlebars from 'handlebars';
import { Options } from './options';
/**
 * Handlebars manager
 */
export declare class HandlebarsManager {
    instance: typeof Handlebars;
    readCustomJsFile(options: Options): void;
}
