#![cfg_attr(not(feature = "std"), no_std)]

use ink_lang as ink;

#[ink::contract]
mod contract_deployer {
    use ink_prelude::{string::String, vec::Vec};

    /// Contract Strorage
    /// owner: the account id of contract's owner
    /// deploy_approver: the account id of the deploy approver
    /// preset_contracts: the preset contracts
    #[ink(storage)]
    pub struct ContractDeployer {
        /// Stores a single `bool` value on the storage.
        owner: AccountId,
        deploy_approver: Option<AccountId>,
        preset_contracts: Vec<(String, Balance, bool, Vec<u8>)>,
    }

    impl ContractDeployer {
        /// Construct of ContractDeployer
        /// owner: the account id of contract's owner
        #[ink(constructor)]
        pub fn new(owner: AccountId) -> Self {
            Self {
                owner,
                deploy_approver: None,
                preset_contracts: Vec::new(),
            }
        }

        /// Default Construct of ContractDeployer
        /// owner: the account id of caller
        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(Self::env().caller())
        }

        /// Add preset contract
        /// name: the name of the contract
        /// fee: u128 of the fee
        /// disabled: flag indicated as the diabled state of the contract
        /// code_hash: the code hash of the contract
        /// return: true if sucess otherwise false
        #[ink(message)]
        pub fn add_preset_contract(
            &mut self,
            name: String,
            fee: Balance,
            disabled: bool,
            code_hash: Vec<u8>,
        ) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            //ensure the code hash is eq solidity's bytes32
            if code_hash.len() != 32 {
                return false;
            }

            self.preset_contracts.push((name, fee, disabled, code_hash));
            true
        }

        /// Get the count of preset contracts
        /// return: u128
        #[ink(message)]
        pub fn preset_count(&self) -> u128 {
            self.preset_contracts.len() as u128
        }

        /// Disable preset contract
        /// idx: the index of the disable preset contract
        /// Return: true if success
        #[ink(message)]
        pub fn disable_preset_contract(&mut self, idx: u128) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            if let Some(mut item) = self.preset_contracts.get_mut(idx as usize) {
                item.2 = true;
                return true;
            }

            false
        }

        /// Enable disabled preset contract
        /// idx: the index of the disabled preset contract
        /// Return: true if success
        #[ink(message)]
        pub fn enable_preset_contract(&mut self, idx: u128) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            if let Some(mut item) = self.preset_contracts.get_mut(idx as usize) {
                item.2 = false;
                return true;
            }

            false
        }

        /// Update a preset contract's name
        /// idx: the index of the preset contract
        /// name: the name want updated
        /// Return: true if success
        #[ink(message)]
        pub fn update_preset_contract_name(&mut self, idx: u128, name: String) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            if let Some(mut item) = self.preset_contracts.get_mut(idx as usize) {
                item.0 = name;
                return true;
            }

            false
        }

        /// Update a preset contract's fee value
        /// idx: the idex of the preset contract
        /// fee: the value of the fee
        /// Return: true if success
        #[ink(message)]
        pub fn update_preset_contract_fee(&mut self, idx: u128, fee: Balance) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            if let Some(mut item) = self.preset_contracts.get_mut(idx as usize) {
                item.1 = fee;
                return true;
            }

            false
        }

        /// Set deploy approver for this contract
        /// approver: the account id of the approver
        /// Return: true if success
        #[ink(message)]
        pub fn set_deploy_approver(&mut self, approver: AccountId) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            self.deploy_approver = Some(approver);
            true
        }

        /// Deploy preset contract
        /// idx: the index of the preset contract
        /// code_sig: the signature of the contract's code
        /// deploy_hash: the hash of the deploy
        /// deploy_sig: the signature of the deploy
        /// salt: the salt value
        /// byte_code: the byte codes of the preset contract
        #[ink(message)]
        pub fn deploy_preset_contract(
            &mut self,
            _idx: u128,
            _code_sig: Vec<u8>,
            _deploy_hash: Vec<u8>,
            _deploy_sig: Vec<u8>,
            _salt: Vec<u8>,
            _byte_code: Vec<u8>,
        ) -> bool {
            // because of ink don't support any method to depoly a new contract within a contract
            // we just retuturn false
            false
        }
    }

    /// Unit tests in Rust are normally defined within such a `#[cfg(test)]`
    /// module and test functions are marked with a `#[test]` attribute.
    /// The below code is technically just normal Rust code.
    #[cfg(test)]
    mod tests {
        /// Imports all the definitions from the outer scope so we can use them here.
        use super::*;

        /// Imports `ink_lang` so we can use `#[ink::test]`.
        use ink_lang as ink;

        /// We test if the default constructor does its job.
        #[ink::test]
        fn default_works() {
            let contract_deployer = ContractDeployer::default();
            assert_eq!(contract_deployer.preset_count(), 0);
        }

        fn new_works() {
            let contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
        }

        #[ink::test]
        fn add_preset_contrct() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );
            assert_eq!(contract_deployer.preset_count(), 1);
        }

        #[ink::test]
        fn enable_preset_contract_success_when_exist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );
            assert_eq!(contract_deployer.preset_count(), 1);
            assert_eq!(contract_deployer.enable_preset_contract(0), true);
            assert_eq!(contract_deployer.preset_contracts[0].2, false);
        }

        #[ink::test]
        fn enable_preset_contract_failed_when_nonexist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );
            assert_eq!(contract_deployer.preset_count(), 1);
            assert_eq!(contract_deployer.enable_preset_contract(1), false);
        }

        #[ink::test]
        fn disable_preset_contract_success_when_exist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );
            assert_eq!(contract_deployer.preset_count(), 1);
            assert_eq!(contract_deployer.enable_preset_contract(0), true);
            assert_eq!(contract_deployer.preset_contracts[0].2, false);
            assert_eq!(contract_deployer.disable_preset_contract(0), true);
            assert_eq!(contract_deployer.preset_contracts[0].2, true);
        }

        #[ink::test]
        fn disable_preset_contract_failed_when_nonexist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );
            assert_eq!(contract_deployer.preset_count(), 1);
            assert_eq!(contract_deployer.enable_preset_contract(0), true);
            assert_eq!(contract_deployer.preset_contracts[0].2, false);
            assert_eq!(contract_deployer.disable_preset_contract(1), false);
            assert_eq!(contract_deployer.preset_contracts[0].2, false);
        }

        #[ink::test]
        fn update_contract_name_success_when_exist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );

            assert_eq!(
                contract_deployer.update_preset_contract_name(0, String::from("contract1-new")),
                true
            );

            assert_eq!(contract_deployer.preset_contracts[0].0, "contract1-new");
        }

        #[ink::test]
        fn update_contract_name_failed_when_nonexist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );

            assert_eq!(
                contract_deployer.update_preset_contract_name(1, String::from("contract1-new")),
                false
            );
        }

        #[ink::test]
        fn update_contract_fee_success_when_exist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );

            assert_eq!(contract_deployer.update_preset_contract_fee(0, 99), true);
            assert_eq!(contract_deployer.preset_contracts[0].1, 99)
        }

        #[ink::test]
        fn update_contract_fee_failed_when_nonexist() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            contract_deployer.add_preset_contract(
                String::from("contract1"),
                1,
                true,
                Vec::from([0x0; 32]),
            );

            assert_eq!(contract_deployer.update_preset_contract_fee(1, 99), false);
        }

        #[ink::test]
        fn set_deploy_approver_success() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            assert_eq!(
                contract_deployer.set_deploy_approver(AccountId::from([0x00; 32])),
                true
            );
        }

        #[ink::test]
        fn deploy_preset_contract_failed() {
            let mut contract_deployer = ContractDeployer::new(AccountId::from([0x01; 32]));
            assert_eq!(contract_deployer.preset_count(), 0);
            assert_eq!(
                contract_deployer.deploy_preset_contract(1, vec![], vec![], vec![], vec![], vec![]),
                false
            );
        }
    }
}
