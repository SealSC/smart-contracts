#![cfg_attr(not(feature = "std"), no_std)]

use ink_lang as ink;

#[ink::contract]
mod staking_mining {
    use ink_storage::collections::{HashMap, Vec};
    use ink_storage::traits::{PackedLayout, SpreadLayout};

    const REWARD_FACTOR_DECIMALS: u128 = 10000;
    #[derive(scale::Encode, scale::Decode, PackedLayout, SpreadLayout, Debug)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    struct Pool {
        staking_token: AccountId,
        reward_factor: u128,
        closed_time: u64,
        closed_flag: bool,
        created: bool,
    }

    #[derive(scale::Encode, scale::Decode, PackedLayout, SpreadLayout, Debug)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    struct StakeInfo {
        staked_amount: u128,
        last_collect_time: u64,
    }

    #[ink(storage)]
    pub struct StakingMining {
        owner: AccountId,
        reward_token: AccountId,
        pool_list: Vec<Pool>,
        user_stack_info: HashMap<(AccountId, u32), StakeInfo>,
    }

    impl StakingMining {
        #[ink(constructor)]
        pub fn new(owner: AccountId, reward_token: AccountId) -> Self {
            Self {
                owner,
                reward_token,
                pool_list: Vec::new(),
                user_stack_info: HashMap::new(),
            }
        }

        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(Self::env().caller(), Self::env().caller())
        }

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

            true
        }

        #[ink(message)]
        pub fn close_pool(&mut self, pid: u32) -> bool {
            let block_timestamp = self.env().block_timestamp();
            if self.env().caller() == self.owner {
                if let Some(pool) = self.pool_list.get_mut(pid) {
                    if pool.created && !pool.closed_flag {
                        pool.closed_flag = true;
                        pool.closed_time = block_timestamp;
                        return true;
                    }
                }
            }
            false
        }

        #[ink(message)]
        pub fn stake(&mut self, pid: u32, amount: u128) -> bool {
            if self.pool_list.get(pid).is_some() && self.pool_list[pid].created {
                //先把之前的收益提取出来给用户
                if self.collect(pid, self.env().caller(), false) {
                    //todo: 转移用户token到本合约，poolList[_pid].stakingToken.transferFrom(msg.sender, address(this), _amount);
                    if let Some(mut user_staked) =
                        self.user_stack_info.get_mut(&(self.env().caller(), pid))
                    {
                        user_staked.staked_amount += amount;
                    }
                }
            }

            false
        }

        fn collect(&mut self, pid: u32, user: AccountId, exit_flag: bool) -> bool {
            if self.env().caller() == user && self.pool_list.get(pid).is_some() {
                let pool = &self.pool_list[pid];
                if pool.created {
                    let mut current_time = self.env().block_timestamp();
                    // 如果找不到，怎么处理
                    if let Some(mut user_stacked) = self.user_stack_info.get_mut(&(user, pid)) {
                        if pool.closed_flag {
                            if current_time > pool.closed_time {
                                current_time = pool.closed_time;
                            }

                            if current_time > user_stacked.last_collect_time {
                                let _reward_amount = (user_stacked.staked_amount
                                    * u128::from(current_time - user_stacked.last_collect_time)
                                    * pool.reward_factor)
                                    / REWARD_FACTOR_DECIMALS;

                                //todo: 给用户发放奖励: rewardToken.transfer(_user, rewardAmount)
                                if exit_flag {
                                    //todo: poolList[_pid].stakingToken.transfer(user, userStaked.stakedAmount);
                                    user_stacked.staked_amount = 0;
                                }

                                user_stacked.last_collect_time = current_time;
                            }
                        }
                    }
                }
            }

            false
        }
    }
}
