module examples::my_coin {
    use sui::coin;
    use sui::tx_context::{Self, TxContext};
    use std::option;
    use sui::transfer;

    /// The type identifier of coin. The coin will have a type
    /// tag of kind: `Coin<package_object::my_coin::MY_COIN>`
    /// Make sure that the name of the type matches the module's name.
    struct MY_COIN has drop {}

    /// Module initializer is called once on module publish. A treasury
    /// cap is sent to the publisher, who then controls minting and burning
    fun init(witness: MY_COIN, ctx: &mut TxContext) {
        let (treasury_cap, coin_metadata) = coin::create_currency(
            witness,
            6,
            b"ARP",
            b"ArpaCoin",
            b"ArpaCoin is the native token of ArpaChain.",
            option::none(),
            ctx,
        );

        // transfer the `TreasuryCap` to the sender, so they can mint and burn
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));

        // metadata is typically frozen after creation
        transfer::public_freeze_object(coin_metadata);
    }
}