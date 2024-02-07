use dep::std;

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
