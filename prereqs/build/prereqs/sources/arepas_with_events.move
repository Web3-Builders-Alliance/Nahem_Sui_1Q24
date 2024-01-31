/// Extended example of a shared object. Now with addition of events!
module examples::arepas_with_events {
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};

    // This is the only dependency you need for events.
    use sui::event;

    /// For when Coin balance is too low.
    const ENotEnough: u64 = 0;

    /// For when profits are too low.
    const ENotEnoughProfits: u64 = 1;

    /// Capability that grants an owner the right to collect profits.
    struct ShopOwnerCap has key {
        id: UID,
    }

    /// A purchasable Arepa. For simplicity's sake we ignore implementation.
    struct Arepa has key {
        id: UID,
    }

    struct ArepaShop has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>,
    }

    // ====== Events ======

    /// For when someone has purchased an arepa.
    struct ArepaPurchased has drop, copy {
        id: ID,
    }

    /// For when ArepaShop owner has collected profits.
    struct ProfitsCollected has drop, copy {
        amount: u64,
    }

    // ====== Functions ======

    fun init(ctx: &mut TxContext) {
        transfer::transfer(ShopOwnerCap { id: object::new(ctx)}, tx_context::sender(ctx));
        transfer::share_object(ArepaShop { id: object::new(ctx), price: 69, balance: balance::zero() });
    }

    /// Buy an arepa.
    public fun buy_arepa(shop: &mut ArepaShop, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(coin::value(payment) == shop.price, ENotEnough);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);
        balance::join(&mut shop.balance, paid);

        let id = object::new(ctx);
        event::emit(ArepaPurchased { id: object::uid_to_inner(&id) });
        transfer::transfer(Arepa { id }, tx_context::sender(ctx));
    }

    /// Consume arepa and get nothing...
    public fun eat_arepa(a: Arepa) {
        let Arepa { id } = a;
        object::delete(id);
    }

    /// Take coin from `ArepaShop` and transfer it to tx sender.
    /// Requires authorization with `ShopOwnerCap`.
    public fun collect_profits(_: &ShopOwnerCap, shop: &mut ArepaShop, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance::value(&shop.balance);
        assert!(amount > 0, ENotEnoughProfits);

        event::emit(ProfitsCollected { amount });
        coin::take(&mut shop.balance, amount, ctx)
        
    }
}