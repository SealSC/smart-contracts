#include "processors.h"
#include "sol_runtime_info.h"
#include "utils.h"

static bool checkInfo(ERC20TokenInstruction *ins) {
    if(ins->dataLen != sizeof(uint64_t)) {
        sol_log("invalid amount data");
        return false;
    }

    if(!isRentKey(ins->accounts[RENT_ACC_POS].key->x)) {
        sol_log("not rent key");
        return false;
    }

    if(*ins->accounts[INS_TRANSFER_FROM_BALANCE_ACC_POS].lamports == 0) {
        sol_log("user has no token");
        return false;
    }

    TokenBalance  fb = getBalance(&ins->accounts[INS_TRANSFER_FROM_BALANCE_ACC_POS]);
    if(!SolPubkey_same(&fb.owner, ins->signer->key)) {
        sol_log("invalid token owner");
        return false;
    }

    SolPubkey toBalanceKey;
    getBalanceAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->accounts[INS_TRANSFER_TO_ACC_POS].key->x,
            ins->programId,
            &toBalanceKey);

    if(!SolPubkey_same(&toBalanceKey, ins->accounts[INS_TRANSFER_TO_BALANCE_ACC_POS].key)) {
        sol_log("invalid receiver");
        return false;
    }

    if(*ins->accounts[INS_TRANSFER_TO_BALANCE_ACC_POS].lamports == 0) {
        uint64_t ret = createBalanceAccount(
                ins->accounts[TOKEN_ACC_POS].key->x,
                ins->accounts[INS_TRANSFER_TO_ACC_POS].key->x,
                &ins->accounts[INS_TRANSFER_TO_BALANCE_ACC_POS],
                ins,
                &ins->accounts[RENT_ACC_POS],
                0);
        if(SUCCESS != ret) {
            sol_log("create receiver balance failed");
            return false;
        }
    }

    return true;
}

uint64_t transferProcessor(ERC20TokenInstruction *ins) {
    if(!checkInfo(ins)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    bool ret = transfer(
            &ins->accounts[INS_TRANSFER_FROM_BALANCE_ACC_POS],
            &ins->accounts[INS_TRANSFER_TO_BALANCE_ACC_POS],
            *(uint64_t*)ins->data
            );

    if(ret) {
        return SUCCESS;
    } else {
        return ERROR_INVALID_INSTRUCTION_DATA;
    }
}
