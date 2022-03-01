#include "processors.h"
#include "sol_runtime_info.h"
#include "utils.h"

static bool checkInfo(ERC20TokenInstruction *ins, TokenInfo *t, uint64_t *amount) {
    if(ins->dataLen != sizeof(uint64_t)) {
        sol_log("invalid amount data");
        return false;
    }
    *amount = *(uint64_t*)ins->data;
    if(*amount == 0) {
        sol_log("mint amount is zero");
        return false;
    }

    if(!isRentKey(ins->accounts[RENT_ACC_POS].key->x)) {
        sol_log("not rent key");
        return false;
    }

    SolAccountInfo *tokenAcc = &ins->accounts[TOKEN_ACC_POS];
    if(!SolPubkey_same(tokenAcc->owner, ins->programId) || tokenAcc->data_len < TOKEN_ACC_SPACE_SIZE) {
        sol_log("invalid token account");
        return false;
    }

    *t = getTokenInfo(tokenAcc->data);
    if(!SolPubkey_same(&t->creator, ins->signer->key)) {
        sol_log("invalid token creator");
        return false;
    }

    if(!t->mintable) {
        sol_log("not mintable");
        return false;
    }

    if(t->totalSupply + *amount < t->totalSupply) {
        sol_log("amount overflow");
        return false;
    }


    SolPubkey toBalanceKey;
    getBalanceAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->accounts[INS_MINT_TO_ACC_POS].key->x,
            ins->programId,
            &toBalanceKey);

    if(!SolPubkey_same(&toBalanceKey, ins->accounts[INS_MINT_TO_BALANCE_ACC_POS].key)) {
        sol_log("invalid receiver");
        return false;
    }

    return true;
}

static uint64_t mint(ERC20TokenInstruction *ins, TokenInfo *t, uint64_t amount) {
    SolAccountInfo *balanceAcc = &ins->accounts[INS_MINT_TO_BALANCE_ACC_POS];
    if(*(balanceAcc->lamports) == 0) {
        uint64_t ret = createBalanceAccount(
                ins->accounts[TOKEN_ACC_POS].key->x,
                ins->accounts[INS_MINT_TO_ACC_POS].key->x,
                &ins->accounts[INS_MINT_TO_BALANCE_ACC_POS],
                ins,
                &ins->accounts[RENT_ACC_POS],
                *(uint64_t*)ins->data);
        if(SUCCESS != ret) {
            sol_log("create receiver balance failed");
            return ret;
        }
    } else {
        uint64_t balance = *(uint64_t*)balanceAcc->data;
        balance += amount;
        sol_memcpy(balanceAcc->data, (uint8_t *)&balance, sizeof(uint64_t));
    }

    setTokenTotalSupply(ins->accounts[TOKEN_ACC_POS].data, t->totalSupply + amount);
    return SUCCESS;
}

uint64_t mintProcessor(ERC20TokenInstruction *ins) {
    TokenInfo t = {};
    uint64_t amount;
    if(!checkInfo(ins, &t, &amount)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    return mint(ins, &t, amount);
}
