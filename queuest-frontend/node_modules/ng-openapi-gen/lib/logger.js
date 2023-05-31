"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
class Logger {
    constructor(silent = false) {
        this.silent = silent;
    }
    info(message, ...optionalParams) {
        if (!this.silent) {
            console.info(message, ...optionalParams);
        }
    }
    log(message, ...optionalParams) {
        if (!this.silent) {
            console.log(message, ...optionalParams);
        }
    }
    debug(message, ...optionalParams) {
        if (!this.silent) {
            console.debug(message, ...optionalParams);
        }
    }
    warn(message, ...optionalParams) {
        console.warn(message, ...optionalParams);
    }
    error(message, ...optionalParams) {
        console.error(message, ...optionalParams);
    }
}
exports.Logger = Logger;
//# sourceMappingURL=logger.js.map