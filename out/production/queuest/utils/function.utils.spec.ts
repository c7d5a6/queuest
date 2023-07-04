import { FunctionUtils } from './function.utils';

describe('FunctionUtils', () => {
    it('should be defined', () => {
        expect(new FunctionUtils()).toBeDefined();
    });

    it('compose sample number functions', () => {
        const add5 = (x: number): number => {
            return x + 5;
        };
        const multiply10 = (x: number): number => {
            return x * 10;
        };

        expect(FunctionUtils.compose(add5, multiply10)(2)).toEqual(25);
    });

    it('compose sample string functions', () => {
        const get2Letter = (x: string): string => {
            return x.charAt(1);
        };
        const addASD = (x: string): string => {
            return x + 'asd';
        };

        expect(FunctionUtils.compose(addASD, get2Letter)('bas')).toEqual(
            'aasd',
        );
    });
});
