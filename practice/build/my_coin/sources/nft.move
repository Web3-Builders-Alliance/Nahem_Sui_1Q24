module examples::nft {
    use std::string::String;
    use sui::object::{Self, UID};
    use std::vector;

    struct NFT has key, store {
        id: UID,
        name: String,
        traits: vector<String>,
        url: String,
    }
}