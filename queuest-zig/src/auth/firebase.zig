const std = @import("std");
const assert = std.debug.assert;

//https://firebase.google.com/docs/auth/admin/verify-id-tokens
//https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com

const pub_key =
    // \\-----BEGIN CERTIFICATE-----
    \\MIIDHTCCAgWgAwIBAgIJALxicn8ft0SKMA0GCSqGSIb3DQEBBQUAMDExLzAtBgNV
    \\BAMMJnNlY3VyZXRva2VuLnN5c3RlbS5nc2VydmljZWFjY291bnQuY29tMB4XDTI0
    \\MDYyNTA3MzIyOFoXDTI0MDcxMTE5NDcyOFowMTEvMC0GA1UEAwwmc2VjdXJldG9r
    \\ZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
    \\A4IBDwAwggEKAoIBAQDKxftF/KObrrgMU08NyMMhp9UaLCDZBZwiP8MprMyqELdb
    \\HrapYV1kOYovVbyuIPvbgasPrRdTs7nko3gmnI9QiSVrOc5fNE1PdB8Z/vLDX3yy
    \\pMzkoGx+LYDOGIQu2pV/n1fQF3PcBFdxkTIVVCYzZ6lvzKoygDV0mwOONE/mx1X1
    \\3zQ6/Ln1//rVkQzbypKFwsn3GWkuu9m7Zzt5KmunGZsyNB2ljNE7rwP3/2jJ2WS/
    \\5BHiaDC4BaApQak8EjJR0zyRmmlErTXC3IB6yM5lE5RGb3Ap1xrX8d/Vyxlz+fPm
    \\gIZI8yMIRP35sSaoGX6bsokDsthmsYOuGkX+6JR/AgMBAAGjODA2MAwGA1UdEwEB
    \\/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0G
    \\CSqGSIb3DQEBBQUAA4IBAQAn9iwfg/BCwseAqxm47yyN88kQj+a05GhgIeQS7URI
    \\+Gm666FXDEdTP+HeuSUph48qkmpWQ/EFoq420CA1dfMMRvCIjyUgoxg3iiF4ioTX
    \\LtxyhITBGDyJ0XO/qf9rLvyPdn5bJ3qUvVNAR8nUQrcbNGrH7xzDeX8LfHHYjiwc
    \\wKRZwhGdhESTepThf4vVJ2SrHV8Hdr+9tfvFTPmnd8lm7kCUZ4zJoeDHE/71G3L3
    \\KHSlf1WnKF9LR5mM1M/p5WKKB+mMSfAR9lSKuOGAnjy2MCkEczwSHbUvT4P8ZNDw
    \\QWcuIetHbD3jQQ1nKOPcHwBC5+hJOq8uEPnXqlJmEdFq
    // \\-----END CERTIFICATE-----
;
// const sig_base = "TF8sbfeV97nGj8kk8HhmnS_nStkLFJu9ylMcw_aa4giMQpVoqzSf5qnd6aV26fbXbuzl3XyU4doD5ysMwsJgcnFa4JxOEn-OLNtlkuV2DMnC_TLv14HAhp5jFges4OXCZD10KbiHdKTi-U-91IFNGR64_1iIndiOc4MKmV6ZO-hj0Qo9dFS8TfVsH0NPGdJB4slQf9KKtVV6P5NCpQAtL99ybGcH3VOTHN4q0BmfGjIP98NQWLKJ-8a6jg_b76PlQshWxsIJF_AoB1_Hf7yGxIOT_poLprAFH9_6bXRRUhMEuV4SyoQ6WVHeslWPX06WGRbqUHzsciTIdydAcdXBMQ";
const sig_base = "TF8sbfeV97nGj8kk8HhmnS_nStkLFJu9ylMcw_aa4giMQpVoqzSf5qnd6aV26fbXbuzl3XyU4doD5ysMwsJgcnFa4JxOEn-OLNtlkuV2DMnC_TLv14HAhp5jFges4OXCZD10KbiHdKTi-U-91IFNGR64_1iIndiOc4MKmV6ZO-hj0Qo9dFS8TfVsH0NPGdJB4slQf9KKtVV6P5NCpQAtL99ybGcH3VOTHN4q0BmfGjIP98NQWLKJ-8a6jg_b76PlQshWxsIJF_AoB1_Hf7yGxIOT_poLprAFH9_6bXRRUhMEuV4SyoQ6WVHeslWPX06WGRbqUHzsciTIdydAcdXBMQ";
const jwt_base = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjU2OTFhMTk1YjI0MjVlMmFlZDYwNjMzZDdjYjE5MDU0MTU2Yjk3N2QiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiYzdkNWE2IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FBY0hUdGVVUTN3MHNsMWliajhMVjF4WU04TnMwLWJFd2k2MnlvMVZPNTFDdWc9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcXVldWVzdC1jYjg4NSIsImF1ZCI6InF1ZXVlc3QtY2I4ODUiLCJhdXRoX3RpbWUiOjE3MDQ1ODgxNjQsInVzZXJfaWQiOiJWV3RnZFNsZk91ZWJ2Mlh6YW5IRDRkb0tOZkQyIiwic3ViIjoiVld0Z2RTbGZPdWVidjJYemFuSEQ0ZG9LTmZEMiIsImlhdCI6MTcyMDk4NjM5MywiZXhwIjoxNzIwOTg5OTkzLCJlbWFpbCI6ImdvZGluZnJvZ0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwMjk5NTk2MzcxMTIyODA2OTY5NiJdLCJlbWFpbCI6WyJnb2RpbmZyb2dAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ";

const base64 = std.base64.standard.decoderWithIgnore(" \t\r\n");

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
    std.debug.print("\nCertificate: {s}", .{parsed_cert.pubKey()});

    // Signature
    std.debug.print("\n:initial signature: {d}", .{sig_base.len});
    const buff_sig = try allocator.alloc(u8, sig_base.len);
    const encoded_sig = std.mem.trim(u8, sig_base[0..], " \t\r\n");
    const sig_len = try std.base64.url_safe.decoderWithIgnore(" \t\r\n").decode(buff_sig, encoded_sig);
    std.debug.print("\n:signature len: {d}", .{sig_len});

    const pk_components = try std.crypto.Certificate.rsa.PublicKey.parseDer(parsed_cert.pubKey());

    std.debug.print("\nPubKey: {any}", .{pk_components});

    const public_key = std.crypto.Certificate.rsa.PublicKey.fromBytes(pk_components.exponent, pk_components.modulus) catch return error.CertificateSignatureInvalid;
    std.debug.print("\nPubKey: {any}", .{public_key});
    std.debug.print("\nPubKey: {d}", .{pk_components.modulus.len});
    try std.crypto.Certificate.rsa.PSSSignature.verify(256, buff_sig[0..256].*, jwt_base, public_key, std.crypto.hash.sha2.Sha256);
    // const em_dec = std.crypto.Certificate.rsa.encrypt(pk_components.modulus.len, buff_sig[0..sig_len].*, public_key) catch |err| switch (err) {
    //     error.MessageTooLong => unreachable,
    // };
    // std.debug.print("\nPubKey: {s}", .{em_dec});
}
