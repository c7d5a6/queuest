import { UserEntity } from './user-entity';

describe('User', () => {
    it('should be defined', () => {
        expect(new UserEntity()).toBeDefined();
    });
});
