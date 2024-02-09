use dep::std;

fn compute_merkle_root_sha256<N>(x: [[u8; 32]; N], s: u8) -> [u8; 32] {
    if s <= 1 {
        x[0]
    } else {
        let mut y: [[u8; 32]; N] = [[0; 32]; N];
        let mut y_size: u8 = 0;
        for i in 0..s {
            if i % 2 == 0 {
                if i + 1 == s {
                    y[y_size] = x[i];
                } else {
                    // concatenate x and y
                    let mut z: [u8; 64] = [0; 64];

                    for b in 0..32 {
                        z[b] = x[i][b];
                        z[b + 32] = x[i + 1][b];
                    }

                    y[y_size] = std::hash::sha256(z);
                }
                y_size += 1;
            }
        }
        compute_merkle_root_sha256(y, s / 2)
    }
}

// concatenate the address and the score into a single string
// string concatenation is not supported using the + operator
fn verify_hash(addresses: [str<42>; 1], scores: [str<2>; 1], expected: [Field; 32]) {
    // pack the address and the score into a single array of bytes
    // the same way as the smart contract does
    let mut packed: [u8; 44] = [0; 44];

    for a in 0..1 {
        let addr = addresses[a].as_bytes();
        let score = scores[a].as_bytes();
        for i in 0..42 {
            packed[i] = addr[i];
        }
        for i in 0..2 {
            packed[i + 42] = score[i];
        }
    }

    std::println("packed");
    std::println(packed);

    // hash the packed array
    let hash = std::hash::keccak256(packed, 44);
    std::println("hash");
    std::println(hash);

    // convert "expected" to bytes and put it on an array of 32 bytes
    // since the assert can only assert arrays of the same size
    let bytes_from_expected = expected; // .as_bytes();
    let mut expected_bytes: [u8; 32] = [0; 32];

    for i in 0..32 {
        expected_bytes[i] = bytes_from_expected[i].to_be_bytes(1)[0];
    }

    std::println("expected");
    std::println(expected_bytes);

    assert(hash == expected_bytes);
}

fn main(addresses: [str<42>; 1], scores: pub [str<2>; 1], expected: [Field; 32]) {
    verify_hash(addresses, scores, expected);
}

#[test]
fn test_demo() {
    main(
        ["0xa6b94ce98d6cd4f447a9c6788f169dd17f65f747"],
        ["85"],
        [
        189, 22, 196, 156, 166, 72, 29, 115, 103, 128, 180, 190, 85, 101, 155, 125, 83, 127, 214, 237, 230, 35, 54, 8, 11, 197, 38, 147, 171, 239, 126, 50
    ]
    );
}

#[test]
fn test_valid_build_merkle_tree() {
    let x = "0x2A5FAB77E8786c0be13E86CC662f9Ee98C178cF3".as_bytes();
    let y = "0x35b8f6f71Ab7Bc464d6a900D8F33c3c287b19bC8".as_bytes();
    let a = "0xe3475047EF9F9231CD6fAe02B3cBc5148E8eB2c8".as_bytes();
    let b = "0x266490c833928159F3803E7E4f17deC3585E570F".as_bytes();

    // 0x98b7658d651929035a1c89d6346ede30b0231b23a39ef91f3dd2ea61eec3af59
    assert(
        compute_merkle_root_sha256(
        [std::hash::sha256(x), std::hash::sha256(y), std::hash::sha256(a), std::hash::sha256(b)],
        4
    )
        == [
            152, 183, 101, 141, 101, 25, 41, 3, 90, 28, 137, 214, 52, 110, 222, 48, 176, 35, 27, 35, 163, 158, 249, 31, 61, 210, 234, 97, 238, 195, 175, 89
        ]
    );
}
