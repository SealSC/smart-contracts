#![cfg_attr(not(feature = "std"), no_std)]

use ink_lang as ink;

#[ink::contract]
mod staking_mining {
    use ink_storage::collections::{HashMap, Vec};
    use ink_storage::traits::{PackedLayout, SpreadLayout};

    const REWARD_FACTOR_DECIMALS: u128 = 10000;

    /// Pool Info
    /// stakeing_token: address of user that staking token
    /// reward_factor: reward factor of the mining pool
    /// closed_time: pool closed time
    /// created: flag indicated as pool is created
    #[derive(scale::Encode, scale::Decode, PackedLayout, SpreadLayout, Debug)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    struct Pool {
        staking_token: AccountId,
        reward_factor: u128,
        closed_time: u64,
        closed_flag: bool,
        created: bool,
    }

    /// Stake Info
    /// staked_amount: amount of staked
    /// last_collect_time: last time of collect earnings
    #[derive(scale::Encode, scale::Decode, PackedLayout, SpreadLayout, Debug)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    struct StakeInfo {
        staked_amount: u128,
        last_collect_time: u64,
    }

    /// Storage of Contract
    /// owner: owner of contract
    /// reward_token: reward token of contract
    /// pool_list: list of mining pool
    /// user_stack_info: user stake info
    #[ink(storage)]
    pub struct StakingMining {
        owner: AccountId,
        reward_token: AccountId,
        pool_list: Vec<Pool>,
        user_staked_info: HashMap<(AccountId, u32), StakeInfo>,
    }

    /// Event of Pool created
    /// stakeing_token: address of stake token mining pool
    /// pid: index of pool list
    /// reward_factor: reward factor of mining pool
    #[ink(event)]
    pub struct PoolCreatedEvent {
        #[ink(topic)]
        staking_token: AccountId,
        #[ink(topic)]
        pid: u32,
        reward_factor: u128,
    }

    /// Event of Pool closed
    /// pid: index of mining pool
    /// timestamp: time of pool closed
    #[ink(event)]
    pub struct PoolClosedEvent {
        #[ink(topic)]
        pid: u32,
        #[ink(topic)]
        timestamp: u64,
    }

    /// Event of User staked
    /// user: address of user
    /// pid: index of mining pool
    /// amount: amount of user staked
    #[ink(event)]
    pub struct UserStakedEvent {
        #[ink(topic)]
        user: AccountId,
        #[ink(topic)]
        pid: u32,
        amount: u128,
    }

    /// Event of User collect earnings
    /// user: address of user
    /// pid: index of mining pool
    /// amount: amount of collect earnings
    #[ink(event)]
    pub struct UserColllectEvent {
        #[ink(topic)]
        user: AccountId,
        #[ink(topic)]
        pid: u32,
        amount: u128,
    }

    /// Event of User exit staked mining pool
    /// user: address of user
    /// pid: index of mining pool
    /// withdraw_amount: amount of principal when user exit
    #[ink(event)]
    pub struct UserExitEvent {
        #[ink(topic)]
        user: AccountId,
        #[ink(topic)]
        pid: u32,
        withdraw_amount: u128,
    }

    impl StakingMining {
        /// contract construct
        /// owner: admin of contract
        /// reward_token: reward token of contract
        #[ink(constructor)]
        pub fn new(owner: AccountId, reward_token: AccountId) -> Self {
            Self {
                owner,
                reward_token,
                pool_list: Vec::new(),
                user_staked_info: HashMap::new(),
            }
        }

        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(Self::env().caller(), Self::env().caller())
        }

        /// Create a new staked mining pool
        /// stakeing_token: address of stake token
        /// reward_factor: reward factor of pool
        #[ink(message)]
        pub fn create_pool(&mut self, staking_token: AccountId, reward_factor: u128) -> bool {
            if self.env().caller() != self.owner {
                return false;
            }

            self.pool_list.push(Pool {
                staking_token,
                reward_factor,
                closed_time: 0,
                closed_flag: false,
                created: true,
            });

            self.env().emit_event(PoolCreatedEvent {
                staking_token,
                pid: self.pool_list.len() - 1,
                reward_factor,
            });

            true
        }

        /// Close staked mining pool
        /// pid: index of pool
        /// must called by admin
        #[ink(message)]
        pub fn close_pool(&mut self, pid: u32) -> bool {
            let block_timestamp = self.env().block_timestamp();
            if self.env().caller() == self.owner {
                if let Some(pool) = self.pool_list.get_mut(pid) {
                    if pool.created && !pool.closed_flag {
                        pool.closed_flag = true;
                        pool.closed_time = block_timestamp;
                        self.env().emit_event(PoolClosedEvent {
                            pid,
                            timestamp: block_timestamp,
                        });
                        return true;
                    }
                }
            }
            false
        }

        /// User stake token
        /// pid: index of pool
        /// amount: amount of staked
        #[ink(message)]
        pub fn stake(&mut self, pid: u32, amount: u128) -> bool {
            if self.pool_list.get(pid).is_some() && self.pool_list[pid].created {
                let user = self.env().caller();
                //先把之前的收益提取出来给用户
                if self.collect(pid, user, false) {
                    //todo: 转移用户token到本合约，poolList[_pid].stakingToken.transferFrom(msg.sender, address(this), _amount);
                    if let Some(mut user_staked) = self.user_staked_info.get_mut(&(user, pid)) {
                        user_staked.staked_amount += amount;
                        self.env().emit_event(UserStakedEvent { user, pid, amount });
                        return true;
                    }
                }
            }

            false
        }

        /// User collect earnings
        /// pid: index of pool
        /// user: address of user
        /// exit_flag: indicated as user exit
        fn collect(&mut self, pid: u32, user: AccountId, exit_flag: bool) -> bool {
            if self.env().caller() == user && self.pool_list.get(pid).is_some() {
                let pool = &self.pool_list[pid];
                if pool.created {
                    let mut current_time = self.env().block_timestamp();
                    // 如果找不到，怎么处理
                    if let Some(mut user_stacked) = self.user_staked_info.get_mut(&(user, pid)) {
                        if pool.closed_flag {
                            if current_time > pool.closed_time {
                                current_time = pool.closed_time;
                            }

                            if current_time > user_stacked.last_collect_time {
                                let reward_amount = (user_stacked.staked_amount
                                    * u128::from(current_time - user_stacked.last_collect_time)
                                    * pool.reward_factor)
                                    / REWARD_FACTOR_DECIMALS;

                                //todo: 给用户发放奖励: rewardToken.transfer(_user, rewardAmount)
                                let mut withdraw_amount = None;

                                if exit_flag {
                                    //todo: poolList[_pid].stakingToken.transfer(user, userStaked.stakedAmount);

                                    withdraw_amount = Some(user_stacked.staked_amount);

                                    user_stacked.staked_amount = 0;
                                }

                                user_stacked.last_collect_time = current_time;

                                self.env().emit_event(UserColllectEvent {
                                    user,
                                    pid,
                                    amount: reward_amount,
                                });

                                if let Some(v) = withdraw_amount {
                                    self.env().emit_event(UserExitEvent {
                                        user,
                                        pid,
                                        withdraw_amount: v,
                                    });
                                }
                            }
                        }
                    }
                }
            }

            false
        }
    }
}
