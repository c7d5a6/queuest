import {BadRequestException, Injectable, Logger} from '@nestjs/common';
import {InjectRepository} from '@nestjs/typeorm';
import {In, Repository} from 'typeorm';
import {CollectionItemEntity} from '../persistence/entities/collection-item.entity';
import {ItemRelationEntity} from '../persistence/entities/item-relation.entity';
import {UserService} from './user.service';

export class Edges {
    relations: Map<number, number[]>;
    relationsInverted: Map<number, number[]>;
}

@Injectable()
export class ItemsRelationService {
    private readonly logger = new Logger(ItemsRelationService.name);

    constructor(
        private readonly userService: UserService,
        @InjectRepository(CollectionItemEntity)
        private collectionItemRepository: Repository<CollectionItemEntity>,
        @InjectRepository(ItemRelationEntity)
        private itemRelationRepository: Repository<ItemRelationEntity>,
    ) {
    }

    async removeRelationBetween(userUid: string, itemAId: number, itemBId: number): Promise<void> {
        const relationOptional = await this.itemRelationRepository.findOneBy([{
            itemFrom: {id: itemAId},
            itemTo: {id: itemBId},
        }, {
            itemFrom: {id: itemBId},
            itemTo: {id: itemAId},
        }]);
        if (relationOptional) {
            this.userService.checkUserAccess(userUid, relationOptional.itemFrom.collection.user);
            this.userService.checkUserAccess(userUid, relationOptional.itemTo.collection.user);
            await this.itemRelationRepository.remove(relationOptional);
        }
    }

    async addRelationFromTo(userUid: string, fromId: number, toId: number): Promise<void> {
        const itemFrom = await this.collectionItemRepository.findOneBy({id: fromId});
        console.log("addRelationFromTo", userUid, JSON.stringify(itemFrom));
        this.userService.checkUserAccess(userUid, itemFrom?.collection.user);
        const itemTo = await this.collectionItemRepository.findOneBy({id: toId});
        this.userService.checkUserAccess(userUid, itemTo?.collection.user);
        if (itemFrom?.collection.id && itemFrom?.collection.id !== itemTo?.collection.id) {
            const error = new Error(`Items are from different collections`);
            throw new BadRequestException(error);
        }
        const existReverse = await this.itemRelationRepository.findOneBy({
            itemFrom: {id: toId},
            itemTo: {id: fromId},
        });
        if (existReverse) {
            await this.itemRelationRepository.remove(existReverse);
        }
        const exists = await this.itemRelationRepository.findOneBy({
            itemFrom: {id: fromId},
            itemTo: {id: toId},
        });
        if (!exists) {
            const itemRelation: ItemRelationEntity = new ItemRelationEntity();
            itemRelation.itemFrom = itemFrom!;
            itemRelation.itemTo = itemTo!;
            await this.itemRelationRepository.save(itemRelation);
        }
    }

    async getRelationsMaps(items: CollectionItemEntity[]): Promise<Edges> {
        const edges: Edges = {
            relations: new Map<number, number[]>(),
            relationsInverted: new Map<number, number[]>()
        };
        const itemIds = items.map(i => i.id);
        const relations: ItemRelationEntity[] = await this.itemRelationRepository.findBy([{
            itemFrom: {id: In(itemIds)},
            itemTo: {id: In(itemIds)},
        }]);
        relations.forEach(ir => {
            let fromId = ir.itemFrom.id;
            let toId = ir.itemTo.id;
            if (!edges.relations.has(fromId)) {
                edges.relations.set(fromId, []);
            }
            if (!edges.relationsInverted.has(toId)) {
                edges.relations.set(toId, []);
            }
            edges.relations.get(fromId)?.push(toId);
            edges.relationsInverted.get(toId)?.push(fromId);
        });
        return edges;
    }

    // private async getRelations(items: CollectionItemEntity[]): Promise<Edges> {
    //     const ids: number[] = items.map((i) => i.id);
    //     const itemRelationEntities = await this.itemRelationRepository.findBy([
    //         { itemFrom: { id: In(ids) } },
    //         { itemTo: { id: In(ids) } },
    //     ]);
    //     const relations: Map<number, number[]> = new Map<number, number[]>();
    //     const relationsInverted: Map<number, number[]> = new Map<number, number[]>();
    //     itemRelationEntities.forEach((itemRelation) => {
    //         const fromId = itemRelation.itemFrom.id;
    //         const toId = itemRelation.itemTo.id;
    //         if (!relations.has(fromId)) {
    //             relations.set(fromId, []);
    //         }
    //         if (!relationsInverted.has(toId)) {
    //             relationsInverted.set(toId, []);
    //         }
    //         const index = relations.get(fromId)?.findIndex((value) => value == toId);
    //         if (index == -1) relations.get(fromId)?.push(toId);
    //         const indexInverted = relationsInverted.get(toId)?.findIndex((value) => value == fromId);
    //         if (indexInverted == -1) relationsInverted.get(toId)?.push(fromId);
    //     });
    //     return { relations, relationsInverted };
    // }

    async removeRelationsForItem(collectionItem: CollectionItemEntity): Promise<void> {
        await this.itemRelationRepository.delete({itemFrom: {id: collectionItem.id}});
        await this.itemRelationRepository.delete({itemTo: {id: collectionItem.id}});
    }
}
