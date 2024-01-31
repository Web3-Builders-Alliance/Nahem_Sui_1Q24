module examples::restricted_transfer {
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::sui::SUI;

    /// Paid amount must be equal to the transfer price
    const EWrongAmount: u64 = 0;

    /// A Capability that allows bearer to create new `TitleDeed`s.
    struct GovernmentCapability has key {
        id: UID,
    }

    /// An object that marks a property ownership. Can only be issued
    /// by an authority.
    struct TitleDeed has key {
        id: UID,
        size: u64,
    }

    /// A centralised registry that apporves property ownership 
    /// transfers and collects fees
    struct LandRegistry has key {
        id: UID,
        balance: Balance<SUI>,
        fee: u64,
    }

    /// Create a `LandRegistry` on mpdule init.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            GovernmentCapability { 
                id: object::new(ctx)
            }, 
            tx_context::sender(ctx)
        );
        transfer::share_object(
            LandRegistry { 
                id: object::new(ctx), 
                balance: balance::zero(), 
                fee: 100
            }
        )
    }

    /// Create `TitleDeed` and transfer it to the property owner.
    /// Only owner of the `GovernmentCapability` can perform this action.
    public fun create_title_deed(
        _: &GovernmentCapability,
        for: address,
        size: u64,
        ctx: &mut TxContext,
    ) {
        transfer::transfer(
            TitleDeed {
                id: object::new(ctx),
                size,
            }, 
        for);
    }

    /// A custom transfer function. Required due to `TitleDeed` not having
    /// a `store` ability. All transfers of `TitleDeed`s have to go through
    /// this function and pay a fee to the `LandRegistry`.
    public fun transfer_ownership(
        registry: &mut LandRegistry,
        paper: TitleDeed,
        fee: Coin<SUI>,
        to: address,
    ) {
        assert!(coin::value(&fee) == registry.fee, EWrongAmount);

        // add a payment to the LandRegistry balance
        balance::join(&mut registry.balance, coin::into_balance(fee));

        // transfer the `TitleDeed` to the new owner
        transfer::transfer(paper, to)
    }
}