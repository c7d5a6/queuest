const std = @import("std");
const zap = @import("zap");
const firebase = @import("firebase.zig");

pub const Context = struct {
    user: ?UserMiddleWare.User = null,
    session: ?SessionMiddleWare.Session = null,
};

const Handler = zap.Middleware.Handler(Context);

pub const UserMiddleWare = struct {
    handler: Handler,
    const Self = @This();

    // note: it MUST have all default values!!!
    // This is so that it can be constructed via .{}
    // as we can't expect the listener to know how to initialize our context structs
    const User = struct {
        name: []const u8 = undefined,
        email: []const u8 = undefined,
    };

    pub fn init(other: ?*Handler) Self {
        return .{
            .handler = Handler.init(onRequest, other),
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        const self: *Self = @fieldParentPtr("handler", handler);
        _ = self;

        context.user = User{
            .name = "renerocksai",
            .email = "supa@secret.org",
        };

        const authHeader = zap.Auth.extractAuthHeader(.Bearer, &r);
        std.debug.print("User Middleware: set user in context {?s}\n\n", .{authHeader});

        return handler.handleOther(r, context);
    }
};

// Example session middleware: puts session info into the context
pub const SessionMiddleWare = struct {
    handler: Handler,

    const Self = @This();

    // Just some arbitrary struct we want in the per-request context
    // note: it MUST have all default values!!!
    const Session = struct {
        info: []const u8 = undefined,
        token: []const u8 = undefined,
    };

    pub fn init(other: ?*Handler) Self {
        return .{
            .handler = Handler.init(onRequest, other),
        };
    }

    // we need the handler as a common interface to chain stuff
    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    // note that the first parameter is of type *Handler, not *Self !!!
    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        // this is how we would get our self pointer
        const self: *Self = @fieldParentPtr("handler", handler);
        _ = self;

        context.session = Session{
            .info = "secret session",
            .token = "rot47-asdlkfjsaklfdj",
        };

        std.debug.print("\n\nSessionMiddleware: set session in context {any}\n\n", .{context.session});

        // continue in the chain
        return handler.handleOther(r, context);
    }
};

// Example html middleware: handles the request and sends a response
pub const HtmlMiddleWare = struct {
    handler: Handler,

    const Self = @This();

    pub fn init(other: ?*Handler) Self {
        return .{
            .handler = Handler.init(onRequest, other),
        };
    }

    // we need the handler as a common interface to chain stuff
    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    // note that the first parameter is of type *Handler, not *Self !!!
    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {

        // this is how we would get our self pointer
        const self: *Self = @fieldParentPtr("handler", handler);
        _ = self;

        std.debug.print("\n\nHtmlMiddleware: handling request with context: {any}\n\n", .{context});

        var buf: [1024]u8 = undefined;
        var userFound: bool = false;
        var sessionFound: bool = false;
        if (context.user) |user| {
            userFound = true;
            if (context.session) |session| {
                sessionFound = true;

                std.debug.assert(r.isFinished() == false);
                const message = std.fmt.bufPrint(&buf, "User: {s} / {s}, Session: {s} / {s}", .{
                    user.name,
                    user.email,
                    session.info,
                    session.token,
                }) catch unreachable;
                r.setContentType(.TEXT) catch unreachable;
                r.sendBody(message) catch unreachable;
                std.debug.assert(r.isFinished() == true);
                return true;
            }
        }

        const message = std.fmt.bufPrint(&buf, "User info found: {}, session info found: {}", .{ userFound, sessionFound }) catch unreachable;

        r.setContentType(.TEXT) catch unreachable;
        r.sendBody(message) catch unreachable;
        return true;
    }
};

test "print" {
    std.debug.print("\nAuth print", .{});
    _ = firebase;
}
