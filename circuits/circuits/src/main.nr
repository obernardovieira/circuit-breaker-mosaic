use dep::std;

// this is a simple implementation of a merkle tree root hash
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
fn compute_and_verify_hash<N>(addresses: [str<42>; N], scores: [str<2>; N], expected: [Field; 32]) {
    // pack the address and the score into a single array of bytes
    // the same way as the smart contract does

    // an array needs to have a specified size. We are using 440, given that
    // it is necessary 44 bytes for each address/score pair and there are a max of 10 pairs
    let mut packed: [u8; 440] = [0; 440];
    let mut packed_size: u32 = 0;

    for a in 0..N {
        if addresses[a] != "0x0000000000000000000000000000000000000000" {
            let addr = addresses[a].as_bytes();
            let score = scores[a].as_bytes();
            for i in 0..42 {
                packed[i + a * 44] = addr[i];
            }
            for i in 0..2 {
                packed[i + 42 + a * 44] = score[i];
            }
            packed_size += 1;
        }
    }

    // hash the packed array (but only the used part of it, which is 44 * N bytes long)
    let hash = std::hash::keccak256(packed, 44 * packed_size);

    // convert "expected" to bytes and put it on an array of 32 bytes
    // since the assert can only assert arrays of the same size
    let bytes_from_expected = expected; // .as_bytes();
    let mut expected_bytes: [u8; 32] = [0; 32];

    for i in 0..32 {
        expected_bytes[i] = bytes_from_expected[i].to_be_bytes(1)[0];
    }

    assert(hash == expected_bytes);
}

fn main(
    addresses: [str<42>; 10],
    scores: pub [str<2>; 10],
    expected_hash: [Field; 32],
    expected_merkle_tree_root_hash: [u8; 32]
) {
    compute_and_verify_hash(addresses, scores, expected_hash);
    let mut hashed_addresses: [[u8; 32]; 10] = [[0; 32]; 10];
    for i in 0..10 {
        hashed_addresses[i] = std::hash::sha256(addresses[i].as_bytes());
    }
    // this actually has a problme. It will compute the merkle tree root hash
    // even if there are no addresses. But there is a bug when we try to use a variable in recursive
    // function calls. So for now, we will just ignore this case
    assert(compute_merkle_root_sha256(hashed_addresses, 10) == expected_merkle_tree_root_hash);
}

#[test]
fn test_compute_and_verify_hash() {
    let a = "0x2a5fab77e8786c0be13e86cc662f9ee98c178cf3";
    let b = "0x35b8f6f71ab7bc464d6a900d8f33c3c287b19bc8";
    let a_score = "85";
    let b_score = "75";
    compute_and_verify_hash(
        [a, b],
        [a_score, b_score],
        [
        101, 117, 59, 214, 186, 31, 78, 229, 227, 15, 232, 164, 219, 17, 131, 61, 108, 33, 139, 91, 71, 36, 178, 220, 2, 63, 117, 141, 140, 30, 20, 165
    ]
    );
}

#[test]
fn test_compute_merkle_root_sha256() {
    let a = "0x2a5fab77e8786c0be13e86cc662f9ee98c178cf3".as_bytes();
    let b = "0x35b8f6f71ab7bc464d6a900d8f33c3c287b19bc8".as_bytes();
    let c = "0xe3475047ef9f9231cd6fae02b3cbc5148e8eb2c8".as_bytes();
    let d = "0x266490c833928159f3803e7e4f17dec3585e570f".as_bytes();

    // 0xbf16c21c81facc57d67f9a9a1112b158c4351ec5bb50bb1cd4347ce3a7bdd3c1
    assert(
        compute_merkle_root_sha256([std::hash::sha256(a), std::hash::sha256(b)], 2) == [
            191, 22, 194, 28, 129, 250, 204, 87, 214, 127, 154, 154, 17, 18, 177, 88, 196, 53, 30, 197, 187, 80, 187, 28, 212, 52, 124, 227, 167, 189, 211, 193
        ]
    );

    // 0x5ff1b443633ca92f4f49770be00be04a215b5d947e8c29f05701b1429b641d04
    assert(
        compute_merkle_root_sha256(
        [std::hash::sha256(a), std::hash::sha256(b), std::hash::sha256(c)],
        3
    )
        == [
            93, 133, 241, 209, 110, 102, 225, 11, 11, 17, 238, 83, 134, 114, 192, 104, 176, 159, 222, 6, 166, 90, 4, 9, 250, 194, 220, 229, 93, 205, 112, 147
        ]
    );

    // 0x98b7658d651929035a1c89d6346ede30b0231b23a39ef91f3dd2ea61eec3af59
    assert(
        compute_merkle_root_sha256(
        [std::hash::sha256(a), std::hash::sha256(b), std::hash::sha256(c), std::hash::sha256(d)],
        4
    )
        == [
            31, 182, 41, 98, 200, 176, 76, 85, 124, 124, 226, 138, 140, 97, 232, 159, 175, 4, 136, 12, 187, 152, 115, 63, 103, 167, 255, 48, 189, 15, 144, 29
        ]
    );
}
