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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ItemsService = void 0;
const common_1 = require("@nestjs/common");
const item_entity_1 = require("../persistence/entities/item.entity");
const graph_1 = require("../models/graph");
const graph_service_1 = require("./graph.service");
const item_relation_1 = require("../models/item-relation");
const item_pair_1 = require("../models/item-pair");
const lodash_clonedeep_1 = __importDefault(require("lodash.clonedeep"));
let ItemsService = class ItemsService {
    constructor(graphService) {
        this.graphService = graphService;
        this.items = [];
        this.relations = new Map();
        this.items.push(new item_entity_1.ItemEntity(0, 'The Godfather'));
        this.items.push(new item_entity_1.ItemEntity(1, 'The Shawshank Redemption'));
        this.items.push(new item_entity_1.ItemEntity(2, 'The Dark Knight'));
        this.items.push(new item_entity_1.ItemEntity(3, 'Pulp Fiction'));
        this.items.push(new item_entity_1.ItemEntity(4, 'Forrest Gump'));
        this.items.push(new item_entity_1.ItemEntity(5, 'The Matrix'));
        this.items.push(new item_entity_1.ItemEntity(6, 'Star Wars: Episode IV - A New Hope'));
        this.items.push(new item_entity_1.ItemEntity(7, 'The Silence of the Lambs'));
        this.items.push(new item_entity_1.ItemEntity(8, 'The Lord of the Rings: The Fellowship of the Ring'));
        this.items.push(new item_entity_1.ItemEntity(9, 'Goodfellas'));
        this.items.push(new item_entity_1.ItemEntity(10, 'The Social Network'));
        this.items.push(new item_entity_1.ItemEntity(11, 'Parasite'));
    }
    getItemsSorted() {
        const graph = new graph_1.Graph(this.items.length);
        this.getEdges(graph);
        const result = [];
        this.graphService
            .topologicalSort(graph)
            .forEach((ind) => result.push(this.items[ind]));
        return result;
    }
    addItem(item) {
        item.id = this.items.length;
        this.items.push(item);
    }
    addRelation(relation) {
        var _a, _b;
        this.removeRelationFromTo(relation.to, relation.from);
        if (!this.relations.has(relation.from)) {
            this.relations.set(relation.from, []);
        }
        const index = (_a = this.relations
            .get(relation.from)) === null || _a === void 0 ? void 0 : _a.findIndex((value) => value == relation.to);
        if (index == -1)
            (_b = this.relations.get(relation.from)) === null || _b === void 0 ? void 0 : _b.push(relation.to);
    }
    deleteRelation(relation) {
        this.removeRelationFromTo(relation.from, relation.to);
        this.removeRelationFromTo(relation.to, relation.from);
    }
    getBestPairs(filter) {
        var _a, _b, _c, _d;
        const fromArray = (0, lodash_clonedeep_1.default)(this.items).sort((i1, i2) => {
            var _a, _b, _c, _d;
            return -((_b = (_a = this.relations.get(i1.id)) === null || _a === void 0 ? void 0 : _a.length) !== null && _b !== void 0 ? _b : 0) +
                (2 * Math.random() - 1) +
                ((_d = (_c = this.relations.get(i2.id)) === null || _c === void 0 ? void 0 : _c.length) !== null && _d !== void 0 ? _d : 0);
        });
        const toArray = (0, lodash_clonedeep_1.default)(fromArray);
        const result = [];
        let i = 0;
        let j = 1;
        while (result.length < filter.size && i < fromArray.length) {
            const item1 = fromArray[i];
            const item2 = toArray[j];
            if (item1.id !== item2.id) {
                let itemRelation = undefined;
                const indexOf1 = (_a = this.relations
                    .get(item1.id)) === null || _a === void 0 ? void 0 : _a.findIndex((v) => v === item2.id);
                const indexOf2 = (_b = this.relations
                    .get(item2.id)) === null || _b === void 0 ? void 0 : _b.findIndex((v) => v === item1.id);
                if ((indexOf1 ? indexOf1 : -1) >= 0) {
                    itemRelation = new item_relation_1.ItemRelation(item1.id, item2.id);
                }
                else if ((indexOf2 ? indexOf2 : -1) >= 0) {
                    itemRelation = new item_relation_1.ItemRelation(item2.id, item1.id);
                }
                if (!itemRelation) {
                    const itemPair = new item_pair_1.ItemPair(item1, item2, itemRelation);
                    result.push(itemPair);
                }
                j = (j + 1) % fromArray.length;
            }
            else {
                j = (j + 2) % fromArray.length;
            }
            i++;
        }
        i = 0;
        j = 1;
        while (result.length < filter.size && i < fromArray.length) {
            const item1 = fromArray[i];
            const item2 = toArray[j];
            if (item1.id !== item2.id) {
                let itemRelation = undefined;
                const indexOf1 = (_c = this.relations
                    .get(item1.id)) === null || _c === void 0 ? void 0 : _c.findIndex((v) => v === item2.id);
                const indexOf2 = (_d = this.relations
                    .get(item2.id)) === null || _d === void 0 ? void 0 : _d.findIndex((v) => v === item1.id);
                if ((indexOf1 ? indexOf1 : -1) >= 0) {
                    itemRelation = new item_relation_1.ItemRelation(item1.id, item2.id);
                }
                else if ((indexOf2 ? indexOf2 : -1) >= 0) {
                    itemRelation = new item_relation_1.ItemRelation(item2.id, item1.id);
                }
                if (!!itemRelation) {
                    const itemPair = new item_pair_1.ItemPair(item1, item2, itemRelation);
                    result.push(itemPair);
                }
                j = (j + 1) % fromArray.length;
            }
            else {
                j = (j + 2) % fromArray.length;
            }
            i++;
        }
        return result;
    }
    removeRelationFromTo(from, to) {
        var _a, _b;
        if (this.relations.has(from)) {
            const index = (_a = this.relations
                .get(from)) === null || _a === void 0 ? void 0 : _a.findIndex((value) => value == to);
            if ((index || index === 0) && index > -1)
                (_b = this.relations.get(from)) === null || _b === void 0 ? void 0 : _b.splice(index, 1);
        }
    }
    getEdges(graph) {
        for (let i = 0; i < this.items.length; i++) {
            const itemEntity = this.items[i];
            const relations = this.relations.get(itemEntity.id);
            if (relations && relations.length > 0) {
                relations.forEach((value) => {
                    const j = this.items.findIndex((v) => value === v.id);
                    graph.addEdge(i, j);
                });
            }
        }
    }
};
ItemsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [graph_service_1.GraphService])
], ItemsService);
exports.ItemsService = ItemsService;
//# sourceMappingURL=items.service.js.map