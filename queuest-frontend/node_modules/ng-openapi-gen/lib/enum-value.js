"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EnumValue = void 0;
const jsesc_1 = __importDefault(require("jsesc"));
const gen_utils_1 = require("./gen-utils");
/**
 * Represents a possible enumerated value
 */
class EnumValue {
    constructor(type, name, description, _value, options) {
        this.type = type;
        this.options = options;
        const value = String(_value);
        this.name = name || (0, gen_utils_1.enumName)(value, options);
        this.description = description || this.name;
        if (this.name === '') {
            this.name = '_';
        }
        if (this.description === '') {
            this.description = this.name;
        }
        if (type === 'string') {
            this.value = `'${(0, jsesc_1.default)(value)}'`;
        }
        else {
            this.value = value;
        }
    }
}
exports.EnumValue = EnumValue;
//# sourceMappingURL=enum-value.js.map