import {Injectable, Logger, UnauthorizedException} from '@nestjs/common';
import {InjectRepository} from '@nestjs/typeorm';
import {UserEntity} from '../persistence/entities/user.entity';
import {QueryFailedError, Repository} from 'typeorm';
import {FirebaseUser} from '../auth/firebase-user';
import {AccessDeniedError} from 'sequelize';

@Injectable()
export class UserService {
    private readonly logger = new Logger(UserService.name);

    constructor(
        @InjectRepository(UserEntity)
        private userRepository: Repository<UserEntity>,
    ) {
    }

    findAll(): Promise<UserEntity[]> {
        // return new Promise<User[]>((resolve) => []);
        return this.userRepository.find();
    }

    findOne(id: number): Promise<UserEntity | null> {
        // return new Promise<User>((resolve) => null);
        return this.userRepository.findOneBy({id});
    }

    save(): void {
        const user = new UserEntity();
        user.email = 'test2@tesst.com';
        user.uid = 'uid';
        this.userRepository.save(user);
    }

    async syncFirebaseUser(user: FirebaseUser): Promise<UserEntity | null> {
        const find = await this.userRepository.findOneBy({uid: user.uid});
        if (find !== null) {
            return find;
        }
        this.logger.log(`User ${user.email} is not found. Saving with uid ${user.uid}.`);
        const userEntity = new UserEntity();
        userEntity.email = user.email;
        userEntity.uid = user.uid;
        // return await this.userRepository.save(userEntity);
        try {
            return await this.userRepository.save(userEntity);
        } catch (ex: any) {
            if (ex instanceof QueryFailedError && ex.message.includes("unq_user_uuid")) {
                return await this.userRepository.findOneBy({uid: user.uid});
            } else throw ex;
        }
    }

    checkUserAccess(uid: string, user: UserEntity | undefined) {
        if (user?.uid !== uid) {
            const error = new Error(`User ${uid} can't access this`);
            throw new AccessDeniedError(error);
        }
    }
}
