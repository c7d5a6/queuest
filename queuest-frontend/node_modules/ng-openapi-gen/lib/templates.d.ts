import { Globals } from './globals';
/**
 * Holds all templates, and know how to apply them
 */
export declare class Templates {
    private templates;
    private globals;
    constructor(builtInDir: string, customDir: string, handlebars: typeof Handlebars);
    private parseTemplate;
    /**
     * Sets a global variable, that is, added to the model of all templates
     */
    setGlobals(globals: Globals): void;
    private baseName;
    /**
     * Applies a template with a given model
     * @param templateName The template name (file without .handlebars extension)
     * @param model The model variables to be passed in to the template
     */
    apply(templateName: string, model?: {
        [key: string]: any;
    }): string;
}
