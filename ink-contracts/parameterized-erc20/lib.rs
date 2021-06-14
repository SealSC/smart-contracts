#![cfg_attr(not(feature = "std"), no_std)]

use ink_lang as ink;

#[ink::contract]
mod parameterized_erc20 {
    use ink_prelude::{string::String, vec::Vec};
    use ink_storage::collections::HashMap;

    /// Defines the storage of your contract.
    /// Add new fields to the below struct in order
    /// to add new static storage fields to your contract.
    #[ink(storage)]
    pub struct ParameterizedErc20 {
        owner: AccountId,
        name: String,
        symbol: String,
        minable: bool,
        decimals: u8,
        total_supply: Balance,
        mint_enable_status: bool,
        balance_of: HashMap<AccountId, Balance>,
        minters: HashMap<AccountId, (Balance, bool)>,
        black_list: HashMap<AccountId, bool>,
    }

    #[ink(event)]
    pub struct AddMinterEvent {
        #[ink(topic)]
        minter: AccountId,
        factor: Balance,
    }

    #[ink(event)]
    pub struct RemoveMinterEvent {
        #[ink(topic)]
        minter: AccountId,
        factor: Balance,
    }

    #[ink(event)]
    pub struct TransferEvent {
        from: AccountId,
        to: AccountId,
        value: Balance,
    }

    #[ink(event)]
    pub struct MintToEvent {
        minter: AccountId,
        to: AccountId,
        amount: Balance,
    }

    impl ParameterizedErc20 {
        /// Constructor that initializes the `bool` value to the given `init_value`.
        #[ink(constructor)]
        pub fn new(
            owner: AccountId,
            name: String,
            symbol: String,
            decimals: u8,
            minable: bool,
            _init_supply: Balance,
        ) -> Self {
            Self {
                owner,
                name,
                symbol,
                decimals,
                minable,
                total_supply: 0,
                mint_enable_status: false,
                minters: HashMap::new(),
                balance_of: HashMap::new(),
                black_list: HashMap::new(),
            }
        }

        /// Constructor that initializes the `bool` value to `false`.
        ///
        /// Constructors can delegate to other constructors.
        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(
                Self::env().caller(),
                String::new(),
                String::new(),
                0,
                false,
                0,
            )
        }

        #[ink(message)]
        pub fn set_mint_enable_status(&mut self, enabled: bool) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }
            self.mint_enable_status = enabled;
            true
        }

        #[ink(message)]
        pub fn add_minter(&mut self, address: AccountId, factor: Balance) -> bool {
            if self.minters.contains_key(&address) {
                return false;
            }
            self.minters
                .entry(address)
                .and_modify(|info| info.1 = false)
                .or_insert((factor, false));
            self.env().emit_event(AddMinterEvent {
                minter: address,
                factor,
            });
            true
        }

        #[ink(message)]
        pub fn update_minter_factor(&mut self, minters: Vec<AccountId>, factor: Balance) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }
            for minter in &minters {
                self.minters.entry(*minter).and_modify(|f| f.0 = factor);
            }
            true
        }

        #[ink(message)]
        pub fn remove_minter(&mut self, minter: AccountId) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            if self.minters.contains_key(&minter) && !self.minters[&minter].1 {
                self.minters[&minter].1 = true;
                self.env().emit_event(RemoveMinterEvent {
                    minter,
                    factor: self.minters[&minter].0,
                });
                return true;
            }

            false
        }

        #[ink(message)]
        pub fn add_to_blacklist(&mut self, minter: AccountId) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            self.black_list
                .entry(minter)
                .and_modify(|enable| *enable = true)
                .or_insert(true);

            true
        }

        #[ink(message)]
        pub fn remove_from_blacklist(&mut self, minter: AccountId) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            self.black_list
                .entry(minter)
                .and_modify(|enable| *enable = false)
                .or_insert(false);

            true
        }

        #[ink(message)]
        pub fn mint(&mut self, to: AccountId, amount: Balance) -> bool {
            if self.minable && self.mint_enable_status {
                if let Some(minter) = self.minters.get(&self.env().caller()) {
                    if minter.1 {
                        return false;
                    }

                    let actual_amount = amount * minter.0 / 10u128.pow(18);
                    self.total_supply += actual_amount;
                    self.balance_of
                        .entry(to)
                        .and_modify(|balance| *balance += actual_amount)
                        .or_insert_with(|| actual_amount);

                    self.env().emit_event(TransferEvent {
                        from: AccountId::from([0x0; 32]),
                        to,
                        value: actual_amount,
                    });

                    return true;
                }
            }
            false
        }
    }
}
