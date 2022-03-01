#include "processors.h"
#include "sol_runtime_info.h"
#include "utils.h"

static bool checkInfo(ERC20TokenInstruction *ins) {
    if(ins->dataLen != sizeof(uint64_t)) {
        sol_log("invalid approve amount");
        return false;
    }

    if(!isRentKey(ins->accounts[RENT_ACC_POS].key->x)) {
        sol_log("not rent key");
        return false;
    }

    SolPubkey approveInfoKey;
    getApproveAccountParam(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->accounts[INS_APPROVE_SPENDER_ACC_POS].key->x,
            ins->signer->key->x,
            ins->programId,
            &approveInfoKey);

    if(!SolPubkey_same(&approveInfoKey, ins->accounts[INS_APPROVE_INFO_ACC_POS].key)) {
        sol_log("invalid approve info account");
        return false;
    }

    return true;
}

uint64_t approveProcessor(ERC20TokenInstruction *ins) {
    if(!checkInfo(ins)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    SolAccountInfo *approveInfoAcc = &ins->accounts[INS_APPROVE_INFO_ACC_POS];
    if(*approveInfoAcc->lamports == 0) {
        return createApproveAccount(
                ins->accounts[TOKEN_ACC_POS].key->x,
                ins->accounts[INS_APPROVE_SPENDER_ACC_POS].key->x,
                ins->signer->key->x,
                approveInfoAcc,
                ins,
                &ins->accounts[RENT_ACC_POS],
                *(uint64_t*)ins->data);
    }

    if(*(uint64_t *)approveInfoAcc->data != 0 && *(uint64_t *)ins->data != 0) {
        sol_log("only allow 0->!0 || !0->0");
        return ERROR_INVALID_INSTRUCTION_DATA;
    }

    sol_memcpy(approveInfoAcc->data, ins->data, sizeof(uint64_t));
    return SUCCESS;
}
