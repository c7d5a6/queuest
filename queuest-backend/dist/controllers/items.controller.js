"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ItemsController = void 0;
const common_1 = require("@nestjs/common");
const items_service_1 = require("../services/items.service");
const item_entity_1 = require("../persistence/entities/item.entity");
const swagger_1 = require("@nestjs/swagger");
const item_relation_1 = require("../models/item-relation");
const item_pair_1 = require("../models/item-pair");
const item_pair_filter_1 = require("./filter/item-pair-filter");
let ItemsController = class ItemsController {
    constructor(itemsService) {
        this.itemsService = itemsService;
    }
    getItems() {
        const result = this.itemsService.getItemsSorted();
        return result;
    }
    getBestPairs(exclude) {
        return this.itemsService.getBestPairs(exclude);
    }
    addItem(item) {
        this.itemsService.addItem(item);
    }
    addRelation(relation) {
        this.itemsService.addRelation(relation);
    }
    deleteRelation(relation) {
        this.itemsService.deleteRelation(relation);
    }
};
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOkResponse)({ description: 'Sorted items', type: [item_entity_1.ItemEntity] }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Array)
], ItemsController.prototype, "getItems", null);
__decorate([
    (0, common_1.Get)('pairs'),
    (0, swagger_1.ApiOkResponse)({
        description: 'Get best pairs to compare',
        type: [item_pair_1.ItemPair],
    }),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [item_pair_filter_1.ItemPairFilter]),
    __metadata("design:returntype", Array)
], ItemsController.prototype, "getBestPairs", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [item_entity_1.ItemEntity]),
    __metadata("design:returntype", void 0)
], ItemsController.prototype, "addItem", null);
__decorate([
    (0, common_1.Post)('relation'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [item_relation_1.ItemRelation]),
    __metadata("design:returntype", void 0)
], ItemsController.prototype, "addRelation", null);
__decorate([
    (0, common_1.Delete)('relation'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [item_relation_1.ItemRelation]),
    __metadata("design:returntype", void 0)
], ItemsController.prototype, "deleteRelation", null);
ItemsController = __decorate([
    (0, swagger_1.ApiTags)('Items'),
    (0, common_1.Controller)('items'),
    __metadata("design:paramtypes", [items_service_1.ItemsService])
], ItemsController);
exports.ItemsController = ItemsController;
//# sourceMappingURL=items.controller.js.map