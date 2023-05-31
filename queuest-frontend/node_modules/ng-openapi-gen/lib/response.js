"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Response = void 0;
/**
 * An operation response
 */
class Response {
    constructor(statusCode, description, content, options) {
        this.statusCode = statusCode;
        this.description = description;
        this.content = content;
        this.options = options;
    }
}
exports.Response = Response;
//# sourceMappingURL=response.js.map