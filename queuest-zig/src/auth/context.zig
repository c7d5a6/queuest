pub const Context = struct {
    user: ?Auth = null,
    session: ?Session = null,
};
// note: it MUST have all default values!!!
// This is so that it can be constructed via .{}
// as we can't expect the listener to know how to initialize our context structs
pub const Auth = struct {
    authenticated: bool = false,
    uuid: ?[28]u8 = null,
};
// Just some arbitrary struct we want in the per-request context
// note: it MUST have all default values!!!
pub const Session = struct {
    info: []const u8 = undefined,
    token: []const u8 = undefined,
};
