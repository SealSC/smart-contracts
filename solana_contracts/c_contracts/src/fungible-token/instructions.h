#pragma once

#include <solana_sdk.h>

#define seal_sol_log_64(n) sol_log_64(0,0,0,0,(n))
#define INS_LEN(ins) (sizeof(ins))

#define SIZE_SOL_BUMPS 1

enum {
    INS_ID_ISSUE = 0,
    INS_ID_TRANSFER,
    INS_ID_APPROVE,
    INS_ID_TRANSFER_FROM,
    INS_ID_MINT,
    INS_ID_BURN,
    INS_ID_ENUM_END
};

typedef struct {
    uint8_t accNum;
    uint8_t id;
    SolPubkey owner;
    uint64_t dataLen;
    const uint8_t *data;
    SolAccountInfo *signer;
    SolAccountInfo *accounts;
    SolPubkey *programId;
} ERC20TokenInstruction;

#define NAME_SIZE 100
#define SYMBOL_SIZE 20
#define TOTAL_SUPPLY_SIZE sizeof(uint64_t)
#define DECIMALS_SIZE 1
#define MINTABLE_FLAG_SIZE 1
#define BURNER_FLAG_SIZE 1
#define CREATOR_SIZE SIZE_PUBKEY
typedef struct {
    uint8_t name[NAME_SIZE];
    uint8_t symbol[SYMBOL_SIZE];
    uint64_t totalSupply;
    uint8_t decimals;
    bool mintable;
    bool burnable;
    SolPubkey creator;
    uint64_t index;
} TokenInfo;

typedef struct {
    uint64_t amount;
    SolPubkey owner;
} TokenBalance;

typedef struct {
    uint64_t allowance;
} ApproveInfo;

//struct alignment may cost more space, but I don't care.
#define TOKEN_ACC_SPACE_SIZE (sizeof(TokenInfo))
#define TOKEN_BALANCE_SIZE (sizeof(TokenBalance))
#define APPROVE_INFO_SIZE (sizeof(ApproveInfo))


enum {
    SIGNER_ACC_POS = 0,
    SYS_ACC_POS,
    RENT_ACC_POS,
    TOKEN_ACC_POS,
    COMMON_ACC_END,
};

enum {
    INS_ISSUE_BASE_ACC_POS = COMMON_ACC_END,
    INS_ISSUE_BALANCE_ACC_POS,
    INS_ISSUE_ACC_END
};

enum {
    INS_TRANSFER_TO_ACC_POS = COMMON_ACC_END,
    INS_TRANSFER_FROM_BALANCE_ACC_POS,
    INS_TRANSFER_TO_BALANCE_ACC_POS,
    INS_TRANSFER_ACC_END,
};

enum {
    INS_APPROVE_SPENDER_ACC_POS = COMMON_ACC_END,
    INS_APPROVE_INFO_ACC_POS,
    INS_APPROVE_ACC_END,
};

enum {
    INS_TRANSFER_FROM_OWNER_ACC_POS = COMMON_ACC_END,
    INS_TRANSFER_FROM_TO_ACC_POS,
    INS_TRANSFER_FROM_OWNER_BALANCE_ACC_POS,
    INS_TRANSFER_FROM_TO_BALANCE_ACC_POS,
    INS_TRANSFER_FROM_APPROVE_INFO_ACC_POS,
    INS_TRANSFER_FROM_ACC_END,
};

enum {
    INS_MINT_TO_ACC_POS = COMMON_ACC_END,
    INS_MINT_TO_BALANCE_ACC_POS,
    INS_MINT_ACC_END,
};

enum {
    INS_BURN_OWNER_BALANCE_ACC_POS = COMMON_ACC_END,
    INS_BURN_ACC_END,
};
