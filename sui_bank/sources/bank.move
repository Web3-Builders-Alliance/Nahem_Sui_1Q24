module sui_bank::bank {

    // === Imports ===

    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui_bank::sui_dollar::{Self, CapWrapper, SUI_DOLLAR};

    // === Errors ===

    const ENotEnoughBalance: u64 = 0;
    const EBorrowAmountTooLarge: u64 = 1;
    const EAccountMustBeEmpty: u64 = 2;
    const EPayYourLoanFirst: u64 = 3;
    const ECannotRepayMoreThanDebt: u64 = 4;

    // === Constants ===

    const FEE: u8 = 5; // Represents a % fee taken on deposits (i.e. 5% fee)
    const EXCHANGE_RATE: u8 = 40;

    // === Structs ===

    struct Bank has key {
        id: UID,
        balance: Balance<SUI>,
        admin_balance: Balance<SUI>
    }

    struct Account has key, store {
        id: UID,
        user: address,
        debt: u64,
        deposit: u64
    }

    struct OwnerCap has key, store {
        id: UID
    }

    // === Public-Mutative Functions ===

    public fun new_account(ctx: &mut TxContext): Account {
        Account {
            id: object::new(ctx),
            user: tx_context::sender(ctx),
            debt: 0,
            deposit: 0
        }
    }

    public fun deposit(self: &mut Bank, account: &mut Account, tokens: Coin<SUI>, ctx: &mut TxContext) {
        let full_deposit = coin::value(&tokens);
        let fee = (((full_deposit as u128) * (FEE as u128) / 100) as u64);

        let admin_coin = coin::split(&mut tokens, fee, ctx);
        account.deposit = account.deposit + coin::value(&tokens);

        balance::join(&mut self.balance, coin::into_balance(tokens));
        balance::join(&mut self.admin_balance, coin::into_balance(admin_coin));
    }

    public fun withdraw(self: &mut Bank, account: &mut Account, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        assert!(account.debt == 0, EPayYourLoanFirst);
        assert!(account.deposit >= amount , ENotEnoughBalance);

        account.deposit = account.deposit - amount;
        let balance_to_withdraw = balance::split(&mut self.balance, amount);
        coin::from_balance(balance_to_withdraw, ctx)
    }

    public fun borrow(account: &mut Account, cap: &mut CapWrapper, amount: u64, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
        let max_borrow_amount = account.deposit * (EXCHANGE_RATE as u64);
        assert!(max_borrow_amount <= amount, EBorrowAmountTooLarge);
        account.debt = account.debt + amount;
        sui_dollar::mint(cap, amount, ctx)
    }

    public fun repay(account: &mut Account, cap: &mut CapWrapper, tokens: Coin<SUI_DOLLAR>) {
        assert!(coin::value(&tokens) <= account.debt, ECannotRepayMoreThanDebt);
        let amount_to_repay = sui_dollar::burn(cap, tokens);
        account.debt = account.debt - amount_to_repay;
    }
    // === Public-View Functions ===


    // === Admin Functions ===


    // === Public-Friend Functions ===


    // === Private Functions ===


    // === Test Functions ===

    fun init(ctx: &mut TxContext) {
        let bank = Bank {
            id: object::new(ctx),
            balance: balance::zero(),
            admin_balance: balance::zero()
        };
        transfer::share_object(bank);
        transfer::transfer(OwnerCap { id: object::new(ctx)}, tx_context::sender(ctx));
    }


}