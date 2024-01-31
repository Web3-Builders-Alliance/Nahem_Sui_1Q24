/// Unlike `Owned` objects, `Shared` ones can be accessed by anyone on the
/// network. Extended functionality and accessibility of this kind of objects
/// requires additional effort by securing access if needed.
module examples::arepas {
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext}; 

    /// Error for when Coin balance is too low
    const ENotEnough: u64 = 0;

    /// Capability that grants an owner the right to collect profits
    struct ShowOwnerCap has key {
        id: UID,
    }

    /// A purchasable arepa
    struct Arepa has key {
        id: UID,
    }

    /// A shared object. 'key' ability is required
    struct ArepaShop has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>,
    }

    /// Init function is often ideal place for initializing
    /// a shared object as it is called only once
    ///
    /// To share an object `transfer::share_object` is used
    fun init(ctx: &mut TxContext) {
        transfer::transfer(ShowOwnerCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        // Share the object to make it accessible to everyone
        transfer::share_object(ArepaShop {
            id: object::new(ctx),
            price: 420,
            balance: balance::zero(),
        })
    }

    /// Entry function available to everyone who owns a Coin.
    public fun buy_arepa(shop: &mut ArepaShop, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(coin::value(payment) >= shop.price, ENotEnough);

        // Take amount = `shop.price` from Coin<SUI>
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);

        // Add paid amount to shop balance
        balance::join(&mut shop.balance, paid);

        transfer::transfer(Arepa {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
    }

    /// Eat arepa and get nothing in return
    public fun eat_arepa(arepa: Arepa) {
        let Arepa { id } = arepa;
        object::delete(id);
    }

    /// Take all profits from the shop, only if you are the owner
    public fun take_profits(_: &ShowOwnerCap, shop: &mut ArepaShop, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance::value(&shop.balance);
        coin::take(&mut shop.balance, amount, ctx)
    }
}