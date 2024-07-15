const std = @import("std");
const crypto = std.crypto;
const assert = std.debug.assert;

//https://firebase.google.com/docs/auth/admin/verify-id-tokens
//https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
//
// RSA
// https://www.cs.cornell.edu/courses/cs5430/2015sp/notes/rsa_sign_vs_dec.php

const pub_key =
    // \\-----BEGIN CERTIFICATE-----
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
    // \\-----END CERTIFICATE-----
;
// const sig_base = "TF8sbfeV97nGj8kk8HhmnS_nStkLFJu9ylMcw_aa4giMQpVoqzSf5qnd6aV26fbXbuzl3XyU4doD5ysMwsJgcnFa4JxOEn-OLNtlkuV2DMnC_TLv14HAhp5jFges4OXCZD10KbiHdKTi-U-91IFNGR64_1iIndiOc4MKmV6ZO-hj0Qo9dFS8TfVsH0NPGdJB4slQf9KKtVV6P5NCpQAtL99ybGcH3VOTHN4q0BmfGjIP98NQWLKJ-8a6jg_b76PlQshWxsIJF_AoB1_Hf7yGxIOT_poLprAFH9_6bXRRUhMEuV4SyoQ6WVHeslWPX06WGRbqUHzsciTIdydAcdXBMQ";
const sig_base = "UCopADIJH60STk_rojzzLfgUXXztvpe3Hnvp7MJTlx_MxFDOWEe6FbXlQHM-ygCkic0yNpYt9gDxPHH2uva7YXc3CUyl86Wx88pbmCmIIUo72nUoIWtNEXCm_npB9eO7rEYdiBlY6bxplIjnMnwYA7fljkx113-JzGm-4gUfqB-X65SrOQzF1IH-mFpjWTvI-DfOaNyVdf_8P47si8o8cuKUyXENITOhTu6h5s2MIUwGVf_Q0ZXIePoUlHatn0-qqvoBanJYPGz5rg8J40x-YEQx08CYDm17t7Dyfrvu9e4lk3uGmiUlr9pkZC5dzhgaJToK1o6sJIlgSQhs14SBaw";
// Sha256 of jwtbase: 56fad4c3bd2170bd5d33f76fe33980a5663c35a1a6070fc1247ec370294e8061
const jwt_base = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImMxNTQwYWM3MWJiOTJhYTA2OTNjODI3MTkwYWNhYmU1YjA1NWNiZWMiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiYzdkNWE2IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FBY0hUdGVVUTN3MHNsMWliajhMVjF4WU04TnMwLWJFd2k2MnlvMVZPNTFDdWc9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcXVldWVzdC1jYjg4NSIsImF1ZCI6InF1ZXVlc3QtY2I4ODUiLCJhdXRoX3RpbWUiOjE3MTg3MTMxNDEsInVzZXJfaWQiOiJWV3RnZFNsZk91ZWJ2Mlh6YW5IRDRkb0tOZkQyIiwic3ViIjoiVld0Z2RTbGZPdWVidjJYemFuSEQ0ZG9LTmZEMiIsImlhdCI6MTcyMTA1Nzk0MCwiZXhwIjoxNzIxMDYxNTQwLCJlbWFpbCI6ImdvZGluZnJvZ0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMjk5NTk2MzcxMTIyODA2OTY5NiJdLCJlbWFpbCI6WyJnb2RpbmZyb2dAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ";

const base64 = std.base64.standard.decoderWithIgnore(" \t\r\n");
const digets_bits = 256;

// fn decryptSignature(
//     //  sig_b64: []const u8,
//     allocator: std.mem.Allocator,
//     p_key: crypto.Certificate.rsa.PublicKey,
// ) [digets_bits]u8 {
//     // Signature
//     var signature: [256]u8 = undefined;
//     const encoded_cert = std.mem.trim(u8, sig_base[0..], " \t\r\n");
//     _ = try std.base64.url_safe.decoderWithIgnore(" \t\r\n").decode(&signature, encoded_cert);
//     // encrypting
//     const Modulus = std.crypto.ff.Modulus(4096);
//     const Fe = Modulus.Fe;
//     const m = try Fe.fromBytes(p_key.n, &signature, .big);
//     const e = p_key.n.powPublic(m, p_key.e) catch unreachable;
//     var res: [256]u8 = undefined;
//     e.toBytes(&res, .big) catch unreachable;
//     return res;
// }

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

test "can decode sample certificate" {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    std.debug.print("\n:initial memry: {any}", .{pub_key.len});
    const buff = try allocator.alloc(u8, pub_key.len * 2);

    const encoded_cert = std.mem.trim(u8, pub_key[0..], " \t\r\n");
    std.debug.print("\n1 trim cert len: {d}", .{encoded_cert.len});
    const newlen = try base64.decode(buff, encoded_cert);
    std.debug.print("\n2 new len: {d}", .{newlen});

    const parsed_cert = std.crypto.Certificate.parse(.{
        .buffer = buff,
        .index = 0,
    }) catch |err| switch (err) {
        error.CertificateHasUnrecognizedObjectId => {
            return err;
        },
        else => |e| return e,
    };

    // std.debug.print("\nCertificate: {any}", .{parsed_cert});
    std.debug.print("\nCertificate: {s}", .{parsed_cert.issuer()});

    //Public +1key
    const pk_components = try std.crypto.Certificate.rsa.PublicKey.parseDer(parsed_cert.pubKey());
    std.debug.print("\nCertificate: {s}", .{parsed_cert.pubKey()});
    std.debug.print("\nPubKey: {any}", .{pk_components});

    const public_key = std.crypto.Certificate.rsa.PublicKey.fromBytes(pk_components.exponent, pk_components.modulus) catch return error.CertificateSignatureInvalid;
    std.debug.print("\nPubKey: {any}", .{public_key});
    std.debug.print("\nPubKey: {s}", .{std.fmt.bytesToHex(pk_components.modulus[0..256], .lower)});
    std.debug.print("\nPubKey: {d}", .{pk_components.modulus.len});

    // const decrypted = decryptSignature(
    // //sig_base[0..],
    // allocator, public_key);
    // Signature
    var signature: [256]u8 = undefined;
    // const encoded_cert = std.mem.trim(u8, sig_base[0..], " \t\r\n");
    _ = try std.base64.url_safe.decoderWithIgnore(" \t\r\n").decode(&signature, sig_base);
    // encrypting
    const Modulus = std.crypto.ff.Modulus(4096);
    const Fe = Modulus.Fe;
    const m = try Fe.fromBytes(public_key.n, &signature, .big);
    const e = public_key.n.powPublic(m, public_key.e) catch unreachable;
    var res: [256]u8 = undefined;
    e.toBytes(&res, .big) catch unreachable;

    const message_hashed = hashMessage(jwt_base[0..]);

    try expect(std.mem.eql(u8, &message_hashed, &res));
}
