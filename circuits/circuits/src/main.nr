use dep::std;

fn compute_merkle_root_sha256<N>(data: [[u8; 32]; N], data_size: u8) -> [u8; 32] {
    let mut new_data: [[u8; 32]; N] = [[0; 32]; N];
    let mut new_data_size: u8 = 0;
    for i in 0..data_size {
        // since we are hasing two elemnts at a time
        // we only do anything if the index is even
        if i % 2 == 0 {
            if i + 1 == data_size {
                // if the data size is odd, just copy the last hash
                new_data[new_data_size] = data[i];
            } else {
                // concatenate previous data and compute new hash
                let mut merged_data: [u8; 64] = [0; 64];

                // concatenate the two hashes
                for b in 0..32 {
                    merged_data[b] = data[i][b];
                    merged_data[b + 32] = data[i + 1][b];
                }

                new_data[new_data_size] = std::hash::sha256(merged_data);
            }
            new_data_size += 1;
        }
    }
    // for some reason, if I used "new_data_size" as a parameter,
    // it enters an infinite loop. I have no idea why, but for now
    // this if/else block is a workaround
    if data_size == 1 {
        // this should be the root hash already!
        new_data[0]
    } else if data_size == 3 {
        compute_merkle_root_sha256(new_data, 2)
    } else if data_size % 2 == 0 {
        compute_merkle_root_sha256(new_data, data_size / 2)
    } else {
        compute_merkle_root_sha256(new_data, (data_size / 2) + 1)
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

    // 0x5ff1b443633ca92f4f49770be00be04a215b5d947e8c29f05701b1429b641d04
    assert(
        compute_merkle_root_sha256(
        [std::hash::sha256(x), std::hash::sha256(y), std::hash::sha256(a)],
        3
    )
        == [
            95, 241, 180, 67, 99, 60, 169, 47, 79, 73, 119, 11, 224, 11, 224, 74, 33, 91, 93, 148, 126, 140, 41, 240, 87, 1, 177, 66, 155, 100, 29, 4
        ]
    );

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
