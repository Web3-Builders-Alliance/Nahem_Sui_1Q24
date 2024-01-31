module bank::bank {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field as df;
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;


    // defines a bank Object: it's shared to everyone
    struct Bank has key {
        id: UID
    }

    // defines a Capability: owner is "admin" and can claim the admin balance
    struct OwnerCap has key, store {
        id: UID
    }

    // defines a Map: user_address => balance
    struct UserBalance has copy, drop, store { user: address }

    // defines an Item: admin_balance
    struct AdminBalance has copy, drop, store {}

    // 5% admin fee. u128 to avoid overflow later
    const FEE: u128 = 5;

    fun init(ctx: &mut TxContext) {
        // creates an owner cap and transfers it to the sender
        let owner_cap = OwnerCap { id: object::new(ctx) };
        transfer::transfer(owner_cap, tx_context::sender(ctx));
        
        // creates a bank object
        let bank = Bank { id: object::new(ctx) };

        // creates a dynamic field with an admin balance and set it to zero
        df::add(&mut bank.id, AdminBalance { }, balance::zero<SUI>());

        // shares the bank object for others to use
        transfer::share_object(bank);

    }

    public fun deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
        // calculates the admin fee
        let admin_fee = ((coin::value(&token) as u128) * FEE / 100 as u64);

        // splits deposited tokens into two coins. saves the remainder in admin_coin
        let admin_coin = coin::split<SUI>(&mut token, (admin_fee as u64), ctx);

        // adds the admin fee to the admin balance
        balance::join(
            df::borrow_mut<AdminBalance, Balance<SUI>>(&mut self.id, AdminBalance { }), 
            coin::into_balance(admin_coin)
        );

        // get the depositor address
        let sender = tx_context::sender(ctx);

        // adds the remainder to the user balance if exists. Otherwise,
        // creates a new user balance dynamic field and adds the remainder to it.
        if (df::exists_(&self.id, UserBalance { user: sender })) {
            balance::join(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: sender }),
            coin::into_balance(token));
        } else {
            df::add(&mut self.id, UserBalance { user: sender }, coin::into_balance(token));
        };
    }

    public fun withdraw(self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
        // Returns the user balance if exists and updates their balance to 0. Otherwise, returns zero. 
        if (df::exists_(&self.id, UserBalance { user: tx_context::sender(ctx) })) {
            let user_balance = balance::withdraw_all<SUI>(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: tx_context::sender(ctx) }));
            coin::from_balance(user_balance, ctx)
        } else {
            coin::zero<SUI>(ctx)
        
        }
    }

    public fun partial_withdraw(self: &mut Bank, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        if (df::exists_(&self.id, UserBalance { user: tx_context::sender(ctx) } )) {
            let withdraw_balance = balance::split<SUI>(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: tx_context::sender(ctx) }), amount);
            coin::from_balance(withdraw_balance, ctx)
        } else {
            coin::zero<SUI>(ctx)
        }
    }

    public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
        let fee_balance = balance::withdraw_all(
            df::borrow_mut<AdminBalance, Balance<SUI>>(
                &mut self.id,
                AdminBalance { },
            ));
        coin::from_balance(fee_balance, ctx)
    }

    #[test]
    public fun test_deposit() {
        use sui::test_scenario;
        use sui::coin::{mint_for_testing};

        // define admin and depositor addresses
        let admin = @0xAAAA;
        let depositor = @0xBBBB;

        // first transaction to emulate module initialization
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        init(test_scenario::ctx(scenario));

        // second transaction executed by depositor to deposit
        test_scenario::next_tx(scenario, depositor);

        // take the shared bank object
        let bank_share = test_scenario::take_shared<Bank>(scenario);

        // mint 3000 SUI tokens for depositor. 
        // TODO: make sure this is minted to depositor and not admin
        let deposit_sui = mint_for_testing<SUI>(3000, test_scenario::ctx(scenario));

        // user depostits 3000 SUI tokens into the bank
        deposit(&mut bank_share, deposit_sui, test_scenario::ctx(scenario));

        // returns bank object (is this necessary?)
        test_scenario::return_shared(bank_share);

        // TODO: test withdraw
        // TODO: test partial withdraw
        // TODO: test claim

        // end of test
        test_scenario::end(scenario_val);
    }
}

