#[test_only]
module bank::bank_tests {
    use sui::test_scenario as ts;
    use bank::bank::{Self, Bank, OwnerCap};
    use sui::coin::{mint_for_testing, burn_for_testing};
    use sui::sui::SUI;
    use sui::test_utils::assert_eq;

    const ADMIN: address = @0x1;
    const ALICE: address = @0xa;

    // every time we run a different test we call this helper function
    fun init_test_helper(): ts::Scenario {
        let scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        ts::next_tx(scenario, ADMIN);

        {
            bank::init_for_testing(ts::ctx(scenario));
        };
        scenario_val
    }

    #[test]
    fun test_deposit() {
        // init the test
        let scenario_val = init_test_helper();

        // scenario doesn't have drop, so we pass a mutable reference to the function
        // and we need to destroy it at the very end.
        let scenario = &mut scenario_val;

        // Alice deposits 1000 tokens
        ts::next_tx(scenario, ALICE);

        {
            // we need to take a mutable reference to the bank
            let bank = ts::take_shared<Bank>(scenario);

            // this mints 1000 SUI tokens for Alice
            let coins = mint_for_testing<SUI>(1000, ts::ctx(scenario));

            // Alice deposits 1000 SUI tokens
            bank::deposit(&mut bank, coins, ts::ctx(scenario));

            // Check that Alice's balance is 1000 - 50 (5% admin fee) = 950 $SUI
            assert_eq(bank::get_balance(&bank, ALICE), 950);

            // Check that admin balance is 5% of deposit (50 $SUI)
            assert_eq(bank::get_admin_balance(&bank), 50);

            // Give the bank object back
            ts::return_shared(bank);
        };

        // Destroy the scenario object
        ts::end(scenario_val);
    }

    #[test]
    fun withdraw() {
        // init the test
        let scenario_val = init_test_helper();

        // scenario doesn't have drop, so we pass a mutable reference to the function
        // and we need to destroy it at the very end.
        let scenario = &mut scenario_val;

        // Alice deposits 1000 tokens
        ts::next_tx(scenario, ALICE);

        {
            // we need to take a mutable reference to the bank
            let bank = ts::take_shared<Bank>(scenario);

            // this mints 1000 SUI tokens for Alice
            let coins = mint_for_testing<SUI>(1000, ts::ctx(scenario));

            // Alice deposits 1000 SUI tokens
            bank::deposit(&mut bank, coins, ts::ctx(scenario));

            // Check that Alice's balance is 1000 - 50 (5% admin fee) = 950 $SUI
            assert_eq(bank::get_balance(&bank, ALICE), 950);

            // Check that admin balance is 5% of deposit (50 $SUI)
            assert_eq(bank::get_admin_balance(&bank), 50);

            // Give the bank object back
            ts::return_shared(bank);
        };

        ts::next_tx(scenario, ALICE);

        {
            // we need to take a mutable reference to the bank
            let bank = ts::take_shared<Bank>(scenario);

            // Alice withdraws all her tokens
            let coin = bank::withdraw(&mut bank, ts::ctx(scenario));

            // This gives us back the value and burns the coin object
            let value = burn_for_testing(coin);
            
            // Check that Alice got back her deposit - fees
            assert_eq(value, 950);

            // Check that Alice's balance is 0
            let balance = bank::get_balance(&bank, ALICE);
            assert_eq(balance, 0);

            // Give the bank object back
            ts::return_shared(bank);
        };

        // Destroy the scenario object
        ts::end(scenario_val);
    }

    #[test]
    fun claim() {
        // init the test
        let scenario_val = init_test_helper();

        // scenario doesn't have drop, so we pass a mutable reference to the function
        // and we need to destroy it at the very end.
        let scenario = &mut scenario_val;

        // Alice deposits 1000 tokens
        ts::next_tx(scenario, ALICE);

        {
            // we need to take a mutable reference to the bank
            let bank = ts::take_shared<Bank>(scenario);

            // this mints 1000 SUI tokens for Alice
            let coins = mint_for_testing<SUI>(1000, ts::ctx(scenario));

            // Alice deposits 1000 SUI tokens
            bank::deposit(&mut bank, coins, ts::ctx(scenario));

            // Check that Alice's balance is 1000 - 50 (5% admin fee) = 950 $SUI
            assert_eq(bank::get_balance(&bank, ALICE), 950);

            // Check that admin balance is 5% of deposit (50 $SUI)
            assert_eq(bank::get_admin_balance(&bank), 50);

            // Give the bank object back
            ts::return_shared(bank);
        };

        ts::next_tx(scenario, ADMIN);

        {
            // we need to take a mutable reference to the bank
            let bank = ts::take_shared<Bank>(scenario);

            // we need to take owner capability from admin
            let owner_cap = ts::take_from_sender<OwnerCap>(scenario);

            // admin claims all the fees
            let coin = bank::claim(&owner_cap, &mut bank, ts::ctx(scenario));

            // This gives us back the value and burns the coin object
            let value = burn_for_testing(coin);

            // Check that admin got back all the fees
            assert_eq(value, 50);

            // Give the bank object back
            ts::return_shared(bank);

            // Give the admin cap object back
            ts::return_to_sender<OwnerCap>(scenario, owner_cap);
        };

        // Destroy the scenario object
        ts::end(scenario_val);
    }
}