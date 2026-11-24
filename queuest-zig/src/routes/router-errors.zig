const std = @import("std");
const web = @import("baz");

pub const ControllerError = error{
    InternalError,
    BadRequest,
    NotFound,
};

pub fn httpStatus(err: anyerror) u16 {
    const status: u16 = switch (err) {
        error.NotFound => 404,
        error.BadRequest, error.MissingParam => 400,
        error.InternalError => 500,
        else => web.defaultErrorStatus(err),
    };
    std.debug.assert(status >= 400);
    std.debug.assert(status < 600);
    return status;
}
