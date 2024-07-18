const std = @import("std");
const ArrayList = std.ArrayList;
const crypto = std.crypto;
const Certificate = crypto.Certificate;
const PublicKey = Certificate.rsa.PublicKey;
const json = std.json;
const Client = std.http.Client;
const mem = std.mem;
const Allocator = mem.Allocator;
//
const digets_bits = 256;
const base64Url = std.base64.url_safe.decoderWithIgnore(" \t\r\n");
const base64Std = std.base64.standard.decoderWithIgnore(" \t\r\n");
const Modulus = std.crypto.ff.Modulus(4096);
const Fe = Modulus.Fe;
//
const print = std.debug.print;

const FirebaseError = error{
    CannotLoadPubKeys,
    ErrorLoadingPubKeys,
    TooManyGoolePubKeys,
    MissingCertificateMarkerInGooglePubKey,
    ErrorVerifyingMessage,
};

const GooglePubKey = struct {
    key: [40]u8,
    certificate: [1024]u8,
};

var goole_keys: [3]GooglePubKey = undefined;
var cache_time: i64 = 0;

pub fn verifySignature(allocator: Allocator, key: []const u8, msg: []const u8, sig_b64: []const u8) FirebaseError!bool {
    try checkAndReloadPK(allocator);

    for (goole_keys) |pk| {
        if (mem.eql(u8, &pk.key, key)) {
            const parsed_cert = Certificate.parse(.{
                .buffer = pk.certificate[0..],
                .index = 0,
            }) catch return error.ErrorVerifyingMessage;
            const pk_components = PublicKey.parseDer(parsed_cert.pubKey()) catch return error.ErrorVerifyingMessage;
            const public_key = PublicKey.fromBytes(pk_components.exponent, pk_components.modulus) catch return error.ErrorVerifyingMessage;
            return verifyMessage(msg, sig_b64, public_key) catch return error.ErrorVerifyingMessage;
        }
    }
    print("\nMissing cert {s}\n", .{key});
    return error.MissingCertificateMarkerInGooglePubKey;
}

fn checkAndReloadPK(allocator: Allocator) FirebaseError!void {
    const now = std.time.timestamp();
    if (now > cache_time) {
        try reloadPublicKeys(allocator);
    }
}

fn reloadPublicKeys(allocator: Allocator) FirebaseError!void {
    var arrayList = ArrayList(u8).init(allocator);
    arrayList.ensureTotalCapacity(4 * 1024) catch return error.CannotLoadPubKeys;
    defer arrayList.deinit();

    var client: Client = .{ .allocator = allocator };
    var server_header_buffer: [4 * 1024]u8 = undefined;

    const mili = std.time.microTimestamp();
    const response = client.fetch(.{
        .location = .{ .url = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com" },
        .response_storage = .{ .dynamic = &arrayList },
        .server_header_buffer = &server_header_buffer,
    }) catch return error.ErrorLoadingPubKeys;
    print("\nTime to load cert: {d}\n", .{std.time.microTimestamp() - mili});

    if (response.status != .ok) {
        return error.ErrorLoadingPubKeys;
    }

    // Use the value of max-age in the Cache-Control header of the response from that endpoint to know when to refresh the public keys.
    try updateCacheAge(server_header_buffer[0..]);

    const object = json.parseFromSlice(json.Value, allocator, arrayList.items, .{}) catch return error.CannotLoadPubKeys;
    for (object.value.object.keys(), 0..) |key, i| {
        if (i >= goole_keys.len) {
            return error.TooManyGoolePubKeys;
        }
        @memcpy(&goole_keys[i].key, key);

        const json_value = object.value.object.get(key).?.string;
        const size = std.mem.replacementSize(u8, json_value, "\\n", "\n");
        var cert = allocator.alloc(u8, size) catch return error.CannotLoadPubKeys;
        _ = std.mem.replace(u8, json_value, "\\n", "\n", cert);

        const begin_marker = "-----BEGIN CERTIFICATE-----";
        const end_marker = "-----END CERTIFICATE-----";

        const begin_marker_start = mem.indexOfPos(u8, cert, 0, begin_marker) orelse
            return error.MissingCertificateMarkerInGooglePubKey;
        const cert_start = begin_marker_start + begin_marker.len;
        const cert_end = mem.indexOfPos(u8, cert, cert_start, end_marker) orelse
            return error.MissingCertificateMarkerInGooglePubKey;
        const encoded_cert = mem.trim(u8, cert[cert_start..cert_end], " \t\r\n");

        var buff = allocator.alloc(u8, encoded_cert.len * 4 / 3) catch return error.CannotLoadPubKeys;
        const len = base64Std.decode(buff, encoded_cert) catch return error.ErrorLoadingPubKeys;

        @memcpy(goole_keys[i].certificate[0..len], buff[0..len]);
        @memset(goole_keys[i].certificate[len..], 0);
    }
}

fn updateCacheAge(headers: []u8) FirebaseError!void {
    const begin_marker = "Cache-Control";
    const cache_start = mem.indexOfPos(u8, headers, 0, begin_marker) orelse
        return error.MissingCertificateMarkerInGooglePubKey;
    const max_marker = "max-age=";
    const max_start = max_marker.len + (mem.indexOfPos(u8, headers, cache_start, max_marker) orelse
        return error.MissingCertificateMarkerInGooglePubKey);
    const del_marker = ",";
    const max_end = mem.indexOfPos(u8, headers, max_start, del_marker) orelse
        return error.MissingCertificateMarkerInGooglePubKey;

    const new_time = std.fmt.parseUnsigned(u32, headers[max_start..max_end], 10) catch return error.CannotLoadPubKeys;
    cache_time = std.time.timestamp() + new_time;
}

//https://firebase.google.com/docs/auth/admin/verify-id-tokens
//https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
//
// RSA
// https://www.cs.cornell.edu/courses/cs5430/2015sp/notes/rsa_sign_vs_dec.php
fn verifyMessage(msg: []const u8, sig_b64: []const u8, p_key: PublicKey) !bool {
    // Decrypting
    const decr_sig = try decryptSignature(sig_b64, p_key);
    const message_hashed = hashMessage(msg);

    return mem.eql(u8, &message_hashed, &decr_sig);
}

fn decryptSignature(sig_b64: []const u8, p_key: PublicKey) ![digets_bits]u8 {
    std.debug.print("\ndecryptSignature {s}\n", .{sig_b64});
    var signature: [256]u8 = undefined;
    var res: [256]u8 = undefined;
    // signature
    _ = try base64Url.decode(&signature, sig_b64);
    // encrypting
    const m = try Fe.fromBytes(p_key.n, &signature, .big);
    const e = p_key.n.powPublic(m, p_key.e) catch unreachable;
    e.toBytes(&res, .big) catch unreachable;
    return res;
}

fn hashMessage(message: []const u8) [digets_bits]u8 {
    const prefix = [_]u8{
        0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
        0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
        0x00, 0x04, 0x20,
    };
    var msg_hashed: [crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    crypto.hash.sha2.Sha256.hash(message, &msg_hashed, .{});
    const p_len = 256 - (prefix.len + msg_hashed.len) - 3;
    const message_hashed: [256]u8 =
        [2]u8{ 0, 1 } ++
        ([1]u8{0xff} ** p_len) ++
        [1]u8{0} ++
        prefix ++
        msg_hashed;
    return message_hashed;
}

const expect = std.testing.expect;

const pub_key =
    \\MIIDHTCCAgWgAwIBAgIJAMfzGQUnE/2GMA0GCSqGSIb3DQEBBQUAMDExLzAtBgNV
    \\BAMMJnNlY3VyZXRva2VuLnN5c3RlbS5nc2VydmljZWFjY291bnQuY29tMB4XDTI0
    \\MDcxMTA3MzIzMFoXDTI0MDcyNzE5NDczMFowMTEvMC0GA1UEAwwmc2VjdXJldG9r
    \\ZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
    \\A4IBDwAwggEKAoIBAQC//i5yMxd2NYI7tKqr20kS2ZTJ33BgLI+GEd05taMne8CN
    \\4MfjgJAdW3kEjIvo/Kxc/8fgEhUIxIMTkWQMAG3jYppSprW0hdPBgruEpFuT4NT8
    \\NgwWy1WEkO8vDXKCF0Zxg3tyVhgNlrx1Nn77PhTT/bDjRh9QyvtIgGmJ6qlIsSLz
    \\VZS3SAZiJFAwo2jiLFAqPvVxvb4VO0YFn9MPXOEtUxJeNNJ+OJxaMx0RreMfrnoV
    \\aLVtSCt3sb7i8BnkMVKViLpwT1wLw430GCIiigOmss4/kVu9GbBbDO1U1cVYbEh/
    \\d+Yi4byRMoLr+NymK4xaeI6fQf7aW+KCyaKabcwtAgMBAAGjODA2MAwGA1UdEwEB
    \\/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0G
    \\CSqGSIb3DQEBBQUAA4IBAQB0wzW9Bl5e1pT4ujxepVlk/SJ/sBl5RsAQaxOAtjJ9
    \\5avJe0JOflN9ssSDmRartC++TM2r3LdUgQ5fCTs/426TbiIjvfFqQf4TFoLBLRaX
    \\RHUlaLqBDEbitzbFh1+Vitnps9czJVN/fKCDyqt/3dzPiMjXgssN69jH0oL0QSgb
    \\WDvv5D9gi2gQgGeFscCCbgH2+DLdP/ztuUnZvbA8lQ5nYUcYOu++OMZCY1p5zmgA
    \\bD0sjNw/n5QARdfbkEWtlrx7uqN014DV7qMvxGZCzm0MR4yn4CoUp9aHJgfLI1uH
    \\mS5VG2SdROcOKQilMr23F7C4OVk8B82xhc0FU/YqArHG
;
const sig_base = "UCopADIJH60STk_rojzzLfgUXXztvpe3Hnvp7MJTlx_MxFDOWEe6FbXlQHM-ygCkic0yNpYt9gDxPHH2uva7YXc3CUyl86Wx88pbmCmIIUo72nUoIWtNEXCm_npB9eO7rEYdiBlY6bxplIjnMnwYA7fljkx113-JzGm-4gUfqB-X65SrOQzF1IH-mFpjWTvI-DfOaNyVdf_8P47si8o8cuKUyXENITOhTu6h5s2MIUwGVf_Q0ZXIePoUlHatn0-qqvoBanJYPGz5rg8J40x-YEQx08CYDm17t7Dyfrvu9e4lk3uGmiUlr9pkZC5dzhgaJToK1o6sJIlgSQhs14SBaw";
const jwt_base = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImMxNTQwYWM3MWJiOTJhYTA2OTNjODI3MTkwYWNhYmU1YjA1NWNiZWMiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiYzdkNWE2IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FBY0hUdGVVUTN3MHNsMWliajhMVjF4WU04TnMwLWJFd2k2MnlvMVZPNTFDdWc9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcXVldWVzdC1jYjg4NSIsImF1ZCI6InF1ZXVlc3QtY2I4ODUiLCJhdXRoX3RpbWUiOjE3MTg3MTMxNDEsInVzZXJfaWQiOiJWV3RnZFNsZk91ZWJ2Mlh6YW5IRDRkb0tOZkQyIiwic3ViIjoiVld0Z2RTbGZPdWVidjJYemFuSEQ0ZG9LTmZEMiIsImlhdCI6MTcyMTA1Nzk0MCwiZXhwIjoxNzIxMDYxNTQwLCJlbWFpbCI6ImdvZGluZnJvZ0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMjk5NTk2MzcxMTIyODA2OTY5NiJdLCJlbWFpbCI6WyJnb2RpbmZyb2dAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ";

test "check signature" {
    const mili = std.time.microTimestamp();
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    // const allocator = std.heap.page_allocator;
    const verified = try verifySignature(allocator, "c1540ac71bb92aa0693c827190acabe5b055cbec", jwt_base[0..], sig_base[0..]);
    print("\nTime to load verify: {d}\n", .{std.time.microTimestamp() - mili});
    const verified2 = try verifySignature(allocator, "c1540ac71bb92aa0693c827190acabe5b055cbec", jwt_base[0..], sig_base[0..]);
    print("\nTime to load verify: {d}\n", .{std.time.microTimestamp() - mili});
    try expect(verified);
    try expect(verified2);
}

test "loading google" {
    const mili = std.time.milliTimestamp();
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    try reloadPublicKeys(allocator);
    var cert_found = false;
    for (goole_keys) |pk| {
        if (mem.eql(u8, &pk.key, "5691a195b2425e2aed60633d7cb19054156b977d")) {
            const parsed_cert = try Certificate.parse(.{
                .buffer = pk.certificate[0..],
                .index = 0,
            });
            try expect(parsed_cert.issuer().len > 0);
            cert_found = true;
        }
    }
    try expect(cert_found);
    print("\nTime to load goole: {d}\n", .{std.time.milliTimestamp() - mili});
}

test "can decode sample certificate" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    const buff = try allocator.alloc(u8, pub_key.len * 3 / 4);

    const encoded_cert = mem.trim(u8, pub_key[0..], " \t\r\n");
    _ = try base64Std.decode(buff, encoded_cert);

    const parsed_cert = try std.crypto.Certificate.parse(.{
        .buffer = buff,
        .index = 0,
    });

    //Public +1key
    const pk_components = try PublicKey.parseDer(parsed_cert.pubKey());
    const public_key = PublicKey.fromBytes(pk_components.exponent, pk_components.modulus) catch return error.CertificateSignatureInvalid;

    try expect(try verifyMessage(jwt_base[0..], sig_base[0..], public_key));
}
