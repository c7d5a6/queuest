"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HandlebarsManager = void 0;
const fs_1 = __importDefault(require("fs"));
const Handlebars = __importStar(require("handlebars"));
/**
 * Handlebars manager
 */
class HandlebarsManager {
    constructor() {
        this.instance = Handlebars;
    }
    readCustomJsFile(options) {
        const customDir = options.templates || '';
        // Attempt to find "handlebars.js" in template folder to allow for custom
        // Handlebars settings (ex: adding helpers)
        const handlerbarsJsFile = customDir ? `${customDir}/handlebars.js` : null;
        if (handlerbarsJsFile && fs_1.default.existsSync(handlerbarsJsFile)) {
            // Attempt to import the "handlebars.js" file if it exists
            const handlebarsFn = require(fs_1.default.realpathSync(handlerbarsJsFile));
            if (handlebarsFn && typeof handlebarsFn === 'function') {
                // call imported method and pass the Handlebars instance to allow for helpers to be registered
                handlebarsFn.call(this.instance, this.instance);
            }
        }
    }
}
exports.HandlebarsManager = HandlebarsManager;
//# sourceMappingURL=handlebars-manager.js.map