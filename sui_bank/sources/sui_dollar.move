module sui_bank::sui_dollar {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::object::{Self, UID};

    // one time witness to be used during initialization
    struct SUI_DOLLAR has drop {}

    friend sui_bank::bank;

    struct CapWrapper has key {
        id: UID,
        cap: TreasuryCap<SUI_DOLLAR>
    }

    #[lint_allow(share_owned)]
    fun init(witness: SUI_DOLLAR, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<SUI_DOLLAR>(
            witness, 
            9, 
            b"SUID", 
            b"Sui Dollar", 
            b"Stable coin issued by Sui Bank", 
            option::none(), 
            ctx
        );
        // we don't freeze it so we can update image & url later
        transfer::public_share_object(metadata);
        transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury_cap});
    }

    public(friend) fun mint(cap_wrapper: &mut CapWrapper, amount: u64, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
        coin::mint(&mut cap_wrapper.cap, amount, ctx)
        }

    public entry fun burn(cap_wrapper: &mut CapWrapper, coin: Coin<SUI_DOLLAR>): u64 {
        coin::burn(&mut cap_wrapper.cap, coin)
    }
}