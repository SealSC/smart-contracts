#include "processors.h"
#include "sol_runtime_info.h"
#include "utils.h"

static bool checkInfo(ERC20TokenInstruction *ins, SolAccountInfo *approveInfoAcc, uint64_t *amount, uint64_t *balance) {
    if(ins->dataLen != sizeof(uint64_t)) {
        sol_log("invalid amount data");
        return false;
    }

    if(!isRentKey(ins->accounts[RENT_ACC_POS].key->x)) {
        sol_log("not rent key");
        return false;
    }

    if(*ins->accounts[INS_TRANSFER_FROM_OWNER_BALANCE_ACC_POS].lamports == 0) {
        sol_log("user has no token");
        return false;
    }
    SolPubkey fromBalanceKey;
    getBalanceAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->accounts[INS_TRANSFER_FROM_OWNER_ACC_POS].key->x,
            ins->programId,
            &fromBalanceKey);
    if(!SolPubkey_same(&fromBalanceKey, ins->accounts[INS_TRANSFER_FROM_OWNER_BALANCE_ACC_POS].key)) {
        sol_log("invalid owner balance account");
        return false;
    }

    SolPubkey approveKey;
    getApproveAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->signer->key->x,
            ins->accounts[INS_TRANSFER_FROM_OWNER_ACC_POS].key->x,
            ins->programId,
            &approveKey
            );
    if(!SolPubkey_same(&approveKey, approveInfoAcc->key)) {
        sol_log("invalid token owner");
        return false;
    }

    uint64_t allowance = *(uint64_t*)approveInfoAcc->data;
    *amount = *(uint64_t*)ins->data;
    seal_sol_log_64(allowance);
    seal_sol_log_64(*amount);
    if(allowance < *amount) {
        sol_log("insufficient allowance");
        return false;
    }
    *balance = allowance - *amount;

    SolPubkey toBalanceKey;
    getBalanceAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->accounts[INS_TRANSFER_FROM_TO_ACC_POS].key->x,
            ins->programId,
            &toBalanceKey);

    if(!SolPubkey_same(&toBalanceKey, ins->accounts[INS_TRANSFER_FROM_TO_BALANCE_ACC_POS].key)) {
        sol_log("invalid receiver");
        return false;
    }

    if(*ins->accounts[INS_TRANSFER_FROM_TO_BALANCE_ACC_POS].lamports == 0) {
        uint64_t ret = createBalanceAccount(
                ins->accounts[TOKEN_ACC_POS].key->x,
                ins->accounts[INS_TRANSFER_FROM_TO_ACC_POS].key->x,
                &ins->accounts[INS_TRANSFER_FROM_TO_BALANCE_ACC_POS],
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

uint64_t transferFromProcessor(ERC20TokenInstruction *ins) {
    SolAccountInfo *approveInfoAcc = &ins->accounts[INS_TRANSFER_FROM_APPROVE_INFO_ACC_POS];

    uint64_t amount = 0;
    uint64_t balance = 0;
    if(!checkInfo(ins, approveInfoAcc, &amount, &balance)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    bool ret = transfer(
            &ins->accounts[INS_TRANSFER_FROM_OWNER_BALANCE_ACC_POS],
            &ins->accounts[INS_TRANSFER_FROM_TO_BALANCE_ACC_POS],
            *(uint64_t*)ins->data
    );

    if(ret) {
        sol_memcpy(approveInfoAcc->data, (uint8_t *) &balance, sizeof(uint64_t));
        return SUCCESS;
    } else {
        return ERROR_INVALID_INSTRUCTION_DATA;
    }
}
