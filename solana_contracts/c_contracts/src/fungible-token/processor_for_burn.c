#include "processors.h"
#include "sol_runtime_info.h"
#include "utils.h"

static bool checkInfo(ERC20TokenInstruction *ins, TokenInfo *t, TokenBalance *tb, uint64_t *amount) {
    if(ins->dataLen != sizeof(uint64_t)) {
        sol_log("invalid amount data");
        return false;
    }
    *amount = *(uint64_t*)ins->data;
    if(*amount == 0) {
        sol_log("burn amount is zero");
        return false;
    }

    if(*ins->accounts[INS_BURN_OWNER_BALANCE_ACC_POS].lamports == 0) {
        sol_log("account not exits");
        return false;
    }

    SolPubkey ownerBalanceKey;
    getBalanceAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->signer->key->x,
            ins->programId,
            &ownerBalanceKey);

    if(!SolPubkey_same(&ownerBalanceKey, ins->accounts[INS_BURN_OWNER_BALANCE_ACC_POS].key)) {
        sol_log("invalid burner");
        return false;
    }

    *tb = getBalance(&ins->accounts[INS_BURN_OWNER_BALANCE_ACC_POS]);
    if(tb->amount < *amount) {
        sol_log("insufficient owner balance");
        return false;
    }

    SolAccountInfo *tokenAcc = &ins->accounts[TOKEN_ACC_POS];
    if(tokenAcc->data_len < TOKEN_ACC_SPACE_SIZE || !SolPubkey_same(tokenAcc->owner, ins->programId)) {
        sol_log("invalid token account");
        return false;
    }

    *t = getTokenInfo(tokenAcc->data);
    if(!t->burnable) {
        sol_log("not burnable");
        return false;
    }

    if(t->totalSupply < *amount) {
        sol_log("amount too big");
        return false;
    }

    return true;
}

static uint64_t burn(ERC20TokenInstruction *ins, TokenInfo *t, TokenBalance *tb,uint64_t amount) {
    SolAccountInfo *balanceAcc = &ins->accounts[INS_BURN_OWNER_BALANCE_ACC_POS];
    amount = tb->amount - amount;
    sol_memcpy(balanceAcc->data, (uint8_t *)&amount, sizeof(uint64_t));
    setTokenTotalSupply(ins->accounts[TOKEN_ACC_POS].data, t->totalSupply - amount);
    return SUCCESS;
}

uint64_t burnProcessor(ERC20TokenInstruction *ins) {
    TokenInfo t = {};
    TokenBalance tb = {};
    uint64_t amount;
    if(!checkInfo(ins, &t, &tb, &amount)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    return burn(ins, &t, &tb, amount);
}
