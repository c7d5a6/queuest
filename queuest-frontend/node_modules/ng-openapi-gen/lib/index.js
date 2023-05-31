#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ng_openapi_gen_1 = require("./ng-openapi-gen");
// Run the main function
(0, ng_openapi_gen_1.runNgOpenApiGen)()
    .catch(err => console.error(`Error on API generation: ${err}`));
//# sourceMappingURL=index.js.map