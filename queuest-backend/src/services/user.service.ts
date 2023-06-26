import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { UserEntity } from '../persistence/entities/user-entity';
import { Repository } from 'typeorm';

@Injectable()
export class UserService {
    constructor(
        @InjectRepository(UserEntity)
        private userRepository: Repository<UserEntity>,
    ) {}

    findAll(): Promise<UserEntity[]> {
        // return new Promise<User[]>((resolve) => []);
        return this.userRepository.find();
    }

    findOne(id: number): Promise<UserEntity | null> {
        // return new Promise<User>((resolve) => null);
        return this.userRepository.findOneBy({ id });
    }

    save(): void {
        const user = new UserEntity();
        user.email = 'test2@tesst.com';
        user.uid = 'uid';
        this.userRepository.save(user);
    }
}
