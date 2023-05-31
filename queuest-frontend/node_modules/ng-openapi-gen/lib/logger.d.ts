export declare class Logger {
    silent: boolean;
    constructor(silent?: boolean);
    info(message: string, ...optionalParams: []): void;
    log(message: string, ...optionalParams: []): void;
    debug(message: string, ...optionalParams: []): void;
    warn(message: string, ...optionalParams: []): void;
    error(message: string, ...optionalParams: []): void;
}
