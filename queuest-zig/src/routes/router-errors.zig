const std = @import("std");

pub const ControllerError = error{
    InternalError,
    BadRequest,
    NotFound,
};

pub fn httpStatus(err: ControllerError) u16 {
    const status: u16 = switch (err) {
        error.NotFound => 404,
        error.BadRequest => 400,
        error.InternalError => 500,
    };
    std.debug.assert(status >= 400);
    std.debug.assert(status < 600);
    return status;
}
