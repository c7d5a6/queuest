const std = @import("std");
const parseUnsigned = std.fmt.parseUnsigned;
const json = std.json;
const mem = std.mem;
const Allocator = mem.Allocator;
const zap = @import("zap");
const firebase = @import("firebase.zig");
const contextLib = @import("context.zig");
const Context = contextLib.Context;
const Session = contextLib.Session;
const Auth = contextLib.Auth;

const Handler = zap.Middleware.Handler(Context);
const base64Url = std.base64.url_safe.decoderWithIgnore(" \t\r\n");

const AuthError = error{
    ErrorParsingHeader,
    SignatureDecodingError,
    SignatureWrong,
    ErrorParsingJWT,
    UnsupportedAlg,
    NotFullJWT,
    TokenExpared,
    WrongIssueTime,
    WrongAudience,
    WrongIssuer,
    NoSubject,
    WrongAuthTime,
};

pub const JWTMiddleware = struct {
    handler: Handler,
    allocator: Allocator,
    const Self = @This();

    pub fn init(other: ?*Handler, allocator: Allocator) Self {
        return .{
            .handler = Handler.init(onRequest, other),
            .allocator = allocator,
        };
    }

    pub fn getHandler(self: *Self) *Handler {
        return &self.handler;
    }

    pub fn onRequest(handler: *Handler, r: zap.Request, context: *Context) bool {
        const self: *Self = @fieldParentPtr("handler", handler);
        const authHeader = zap.Auth.extractAuthHeader(.Bearer, &r);
        if (authHeader != null) {
            var arena = std.heap.ArenaAllocator.init(self.allocator);
            defer arena.deinit();
            const allocator = arena.allocator();
            const sub = parseJWT(allocator, authHeader.?) catch |err| {
                r.sendError(err, if (@errorReturnTrace()) |t| t.* else null, 401);
                return false;
            };
            context.user = Auth{
                .authenticated = true,
                .uuid = sub,
            };
            std.debug.print("\nSub: {s}\n", .{sub[0..28]});
            std.debug.print("\nuuid: {s}\n", .{context.user.?.uuid.?[0..28]});
        } else {
            context.user = Auth{
                .authenticated = false,
            };
        }

        return handler.handleOther(r, context);
    }
};

fn parseJWT(allocator: Allocator, jwt: []const u8) AuthError![28]u8 {
    std.debug.print("JWT Middleware: set user in context {?s}\n\n", .{jwt});
    const bearer = zap.Auth.AuthScheme.Bearer.str();
    const jwt_start = bearer.len + (mem.indexOfPos(u8, jwt, 0, bearer) orelse
        return error.ErrorParsingHeader);
    const jwt_body_start = mem.indexOfPos(u8, jwt, jwt_start, ".") orelse
        return error.ErrorParsingHeader;
    const jwt_sig_start = mem.indexOfPos(u8, jwt, jwt_body_start + 1, ".") orelse
        return error.ErrorParsingHeader;

    const key = try parseJWTHead(allocator, jwt[jwt_start..jwt_body_start]);
    const sub = try parseJWTBody(allocator, jwt[jwt_body_start + 1 .. jwt_sig_start]);
    std.debug.print("\nSubject: {s}\n", .{sub});

    const is_signature_ok = firebase.verifySignature(allocator, key[0..], jwt[jwt_start..jwt_sig_start], jwt[jwt_sig_start + 1 ..]) catch return error.SignatureDecodingError;
    if (!is_signature_ok)
        return error.SignatureWrong;
    return sub;
}

fn parseJWTHead(allocator: Allocator, head_base: []const u8) AuthError![]const u8 {
    const buff = allocator.alloc(u8, head_base.len * 3 / 4) catch return error.ErrorParsingJWT;
    const encoded = mem.trim(u8, head_base[0..], " \t\r\n");
    _ = base64Url.decode(buff, encoded) catch return error.ErrorParsingJWT;
    const head = json.parseFromSlice(json.Value, allocator, buff, .{}) catch return error.ErrorParsingJWT;
    std.debug.print("\nJWT: {s}\n", .{buff});
    var alg: bool = false;
    var key: bool = false;
    var typ: bool = false;
    var kid: ?[]const u8 = null;
    for (head.value.object.keys()) |k| {
        const value = head.value.object.get(k).?.string;
        if (mem.eql(u8, "alg", k)) {
            alg = true;
            if (!mem.eql(u8, "RS256", value)) {
                return error.UnsupportedAlg;
            }
        }
        if (mem.eql(u8, "kid", k)) {
            key = true;
            kid = value;
        }
        if (mem.eql(u8, "typ", k)) {
            typ = true;
            if (!mem.eql(u8, "JWT", value)) {
                return error.UnsupportedAlg;
            }
        }
    }
    if (!(alg and key and typ)) {
        return error.NotFullJWT;
    }
    return kid orelse error.ErrorParsingJWT;
}
// exp     Expiration time     Must be in the future. The time is measured in seconds since the UNIX epoch.
// iat     Issued-at time  Must be in the past. The time is measured in seconds since the UNIX epoch.
// aud     Audience    Must be your Firebase project ID, the unique identifier for your Firebase project, which can be found in the URL of that project's console.
// iss     Issuer  Must be "https://securetoken.google.com/<projectId>", where <projectId> is the same project ID used for aud above.
// sub     Subject     Must be a non-empty string and must be the uid of the user or device.
// auth_time   Authentication time     Must be in the past. The time when the user authenticated.
fn parseJWTBody(allocator: Allocator, body_base: []const u8) AuthError![28]u8 {
    const now = std.time.timestamp();
    std.debug.print("\nNow time {d}\n", .{now});
    const buff = allocator.alloc(u8, body_base.len * 3 / 4) catch return error.ErrorParsingJWT;
    const encoded = mem.trim(u8, body_base[0..], " \t\r\n");
    _ = base64Url.decode(buff, encoded) catch return error.ErrorParsingJWT;
    const body = json.parseFromSlice(json.Value, allocator, buff, .{}) catch return error.ErrorParsingJWT;
    std.debug.print("\nJWT: {s}\n", .{buff});
    var exp: bool = false;
    var iat: bool = false;
    var aud: bool = false;
    var iss: bool = false;
    var auth_time: bool = false;
    var sub: ?[28]u8 = null;
    for (body.value.object.keys()) |k| {
        if (mem.eql(u8, "exp", k)) {
            exp = true;
            const time = body.value.object.get(k).?.integer;
            if (time < now) return error.TokenExpared;
        }
        if (mem.eql(u8, "iat", k)) {
            iat = true;
            const time = body.value.object.get(k).?.integer;
            if (time > now) return error.WrongIssueTime;
        }
        if (mem.eql(u8, "aud", k)) {
            aud = true;
            const value = body.value.object.get(k).?.string;
            if (!mem.eql(u8, "queuest-cb885", value)) {
                return error.WrongAudience;
            }
        }
        if (mem.eql(u8, "iss", k)) {
            iss = true;
            const value = body.value.object.get(k).?.string;
            if (!mem.eql(u8, "https://securetoken.google.com/queuest-cb885", value)) {
                return error.WrongIssuer;
            }
        }
        if (mem.eql(u8, "auth_time", k)) {
            auth_time = true;
            const time = body.value.object.get(k).?.integer;
            std.debug.print("\nauth time < now {d} < {d}\n", .{ time, now });
            if (time > now) return error.WrongAuthTime;
        }
        if (mem.eql(u8, "sub", k)) {
            const value = body.value.object.get(k).?.string;
            sub = [_]u8{0} ** 28;
            @memcpy(sub.?[0..28], value[0..28]);
        }
    }
    if (!(exp and iat and aud and iss and auth_time)) {
        return error.NotFullJWT;
    }
    return sub orelse error.NoSubject;
}

const test_jwt_head = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc5M2Y3N2Q0N2ViOTBiZjRiYTA5YjBiNWFkYzk2ODRlZTg1NzJlZTYiLCJ0eXAiOiJKV1QifQ";
const test_jwt_body = "eyJuYW1lIjoiYzdkNWE2IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FBY0hUdGVVUTN3MHNsMWliajhMVjF4WU04TnMwLWJFd2k2MnlvMVZPNTFDdWc9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcXVldWVzdC1jYjg4NSIsImF1ZCI6InF1ZXVlc3QtY2I4ODUiLCJhdXRoX3RpbWUiOjE3MTk5NDUxODgsInVzZXJfaWQiOiJWV3RnZFNsZk91ZWJ2Mlh6YW5IRDRkb0tOZkQyIiwic3ViIjoiVld0Z2RTbGZPdWVidjJYemFuSEQ0ZG9LTmZEMiIsImlhdCI6MTcxOTk0NTE4OCwiZXhwIjoxNzE5OTQ4Nzg4LCJlbWFpbCI6ImdvZGluZnJvZ0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMjk5NTk2MzcxMTIyODA2OTY5NiJdLCJlbWFpbCI6WyJnb2RpbmZyb2dAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ";
const test_jwt_sig = "sJGfYejF54rDyGz_Ff08zXBQvN3Erf4v41S7oGdr5tdn1Fq6kbi1IWhL3F4fQKjPU1fIKkngtXUbQAE5fqHHT0wVSLsizLsOnZyGG_CtPdSULLzPqfql1V64ratMf8CvkNgF5LbO82dnaklAJJdVMlr3E--cWRqPoimLEE_3vza5SDQn6OO8XcjGs86lI05y7jqL9_KQU3obWX1cyh_homXLUmoadBHxhS5y6nySpvDaET_8kf29sYO4kRCmox1Oxl2XkWlPJD17sA0UMmTCf4XPC2BspMR_5oekh13Uqzz2m9zaYNQdoNs5dLrekseOogt7ZBTQuKKhLrZRQc1ZIA";
const test_jwt =
    "Bearer " ++
    test_jwt_head ++
    "." ++ test_jwt_body ++
    "." ++ test_jwt_sig;

test "print" {
    std.debug.print("\nAuth print", .{});
    _ = firebase;
}

test "parse head" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    const kid = try parseJWTHead(allocator, test_jwt_head);
    try std.testing.expectEqualStrings("793f77d47eb90bf4ba09b0b5adc9684ee8572ee6", kid);
}

test "parse jwt" {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    _ = parseJWT(allocator, test_jwt) catch |err| {
        try std.testing.expectEqual(AuthError.TokenExpared, err);
    };
}

test "wrong signature" {
    const jwt = "Bearer " ++ "eyJhbGciOiJSUzI1NiIsImtpZCI6ImMxNTQwYWM3MWJiOTJhYTA2OTNjODI3MTkwYWNhYmU1YjA1NWNiZWMiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiYzdkNWE2IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FBY0hUdGVVUTN3MHNsMWliajhMVjF4WU04TnMwLWJFd2k2MnlvMVZPNTFDdWc9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcXVldWVzdC1jYjg4NSIsImF1ZCI6InF1ZXVlc3QtY2I4ODUiLCJhdXRoX3RpbWUiOjE3MTg3MTMxNDEsInVzZXJfaWQiOiJWV3RnZFNsZk91ZWJ2Mlh6YW5IRDRkb0tOZkQyIiwic3ViIjoiVld0Z2RTbGZPdWVidjJYemFuSEQ0ZG9LTmZEMiIsImlhdCI6MTcyMTQwMDE3OCwiZXhwIjo5NzIxNDAzNzc4LCJlbWFpbCI6ImdvZGluZnJvZ0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMjk5NTk2MzcxMTIyODA2OTY5NiJdLCJlbWFpbCI6WyJnb2RpbmZyb2dAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.MNG6XZGnE13loqTWpTGu_ghCM8UlAjrWjfszRg6oVDSgZqGVn6501mxNh4qRMRIJ3BPz_Ty377gmJgA2ucJLCjgHyy3aApMPBE0DxjHVJ32Tyh88CbbGHjKoFfP9vwbXeatdk8B-ntVO8ZaggPz4vJiuCqlf8E1BipCj301QA7RQlVnDhUhUKnLSO_UnEKwHKyvPb473w4yq698AwbvQQ6_RFbmIe6ZLeH4Ef0ofcodqknHs8xefz_VUV32RDMVfgc8NWyAKEiYd7YYXQg9yu9kb-z6TwN3X-DmFY9cXUehhngsPDxutMkt44AwyWvs5VQ_fRmzrv9TTyiloPflCgg";
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    _ = parseJWT(allocator, jwt) catch |err| {
        try std.testing.expectEqual(AuthError.SignatureWrong, err);
    };
}
