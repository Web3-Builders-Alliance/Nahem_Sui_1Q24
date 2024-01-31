module examples::nft {
    use std::string::String;
    use sui::object::{Self, UID, ID};
    use std::vector;
    use sui::tx_context::{Self, TxContext};

    struct NFT has key, store {
        id: UID,
        name: String,
        traits: vector<String>,
        url: String,
    }

    struct NFTMinted has copy, drop {
        nft_id: ID,
        minted_by: address,
    }

    /// Mint a new NFT with the given `name`, `traits` and `url`.
    /// The object is returned to sender and they're free to transfer
    /// it to themselves or anyone else.
    public fun mint(
        name: String,
        traits: vector<String>,
        url: String,
        ctx: &mut TxContext,
    ) : NFT {
        let id = object::new(ctx);

        event::emit(NFTMinted { 
            id,
            minted_by: context::sender(ctx),
        });

        NFT { id, name, traits, url }
    }

    /// Some nfts get new traits over time... owner of one can
    /// add a new trait to their nft at any time.
    public fun add_trait(
        nft: &mut NFT, trait: String
    ) {
        vector::push_back(&mut nft.traits, trait);
    }




}