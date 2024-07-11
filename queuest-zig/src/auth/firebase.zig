const std = @import("std");
const assert = std.debug.assert;

//https://firebase.google.com/docs/auth/admin/verify-id-tokens

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

test "can decode sample certificate" {
    var cb: std.crypto.Certificate.Bundle = .{};
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    try std.crypto.Certificate.Bundle.addCertsFromFilePathAbsolute(&cb, allocator, "/home/c7d5a6/projects/queuest/queuest-zig/src/auth/cert");

    std.debug.print("0 {any}\n", .{cb.bytes.items});
    const cert = try std.crypto.Certificate.parse(.{ .buffer = cb.bytes.items, .index = 0 });
    std.debug.print("1 {any}\n", .{cert});
    std.debug.print("1 {any}\n", .{cert});
    // const pub_key_seq = try std.crypto.Certificate.der.Element.parse(pub_key, 0);
    // std.debug.print("1 {any}\n", .{pub_key_seq});
    // assert(pub_key_seq.identifier.tag != .sequence);
    // const modulus_elem = try std.crypto.Certificate.der.Element.parse(pub_key, pub_key_seq.slice.start);
    // std.debug.print("2 {any}\n", .{modulus_elem});
    // assert(modulus_elem.identifier.tag != .integer);
    // const exponent_elem = try std.crypto.Certificate.der.Element.parse(pub_key, modulus_elem.slice.end);
    // std.debug.print("3 {any}\n", .{exponent_elem});
    // assert(exponent_elem.identifier.tag != .integer);
    // // Skip over meaningless zeroes in the modulus.
    // const modulus_raw = pub_key[modulus_elem.slice.start..modulus_elem.slice.end];
    // std.debug.print("4 {any}\n", .{modulus_raw});
    // const modulus_offset = for (modulus_raw, 0..) |byte, i| {
    //     if (byte != 0) break i;
    // } else modulus_raw.len;
    // const result = .{
    //     .modulus = modulus_raw[modulus_offset..],
    //     .exponent = pub_key[exponent_elem.slice.start..exponent_elem.slice.end],
    // };
    //
    // std.debug.print("resut {any}\n\n", .{result});
    // const pubK = std.crypto.Certificate.rsa.PublicKey.parseDer(cert_data);
}
