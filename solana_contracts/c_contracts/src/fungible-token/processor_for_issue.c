#include "processors.h"
#include "sol_runtime_info.h"
#include "snsp_invoke.h"
#include "utils.h"

static uint64_t createTokenBaseAccount(
        ERC20TokenInstruction *ins,
        SolAccountInfo *initAcc,
        SolAccountInfo *rent
) {
    uint8_t bumps = 0;
    SolSignerSeed seeds[] = {
            {.addr = ins->signer->key->x, .len = SIZE_PUBKEY},
            {.addr = &bumps, .len = SIZE_SOL_BUMPS},
    };
    bumps = getBump(seeds, SOL_ARRAY_SIZE(seeds) - 1, ins->programId, NULL);

    SNSP_INS_CreateAccountData createData = buildCreateData(sizeof(uint64_t), ins->programId, rent);
    return createAccount(ins,&createData, initAcc->key, seeds, SOL_ARRAY_SIZE(seeds));
}

static bool checkInfo(ERC20TokenInstruction *ins, uint64_t *newAccSeed) {
    //note: token creator is the signer, not included at instruction's data field.
    if(ins->dataLen < (TOKEN_ACC_SPACE_SIZE - CREATOR_SIZE)) {
        sol_log("invalid instruction data");
        return false;
    }

    if(!isRentKey(ins->accounts[RENT_ACC_POS].key->x)) {
        sol_log("not rent key");
        return false;
    }

    if(*ins->accounts[TOKEN_ACC_POS].lamports != 0) {
        sol_log_pubkey(ins->accounts[TOKEN_ACC_POS].key);
        sol_log("token already exist");
        return false;
    }

    if(*(ins->accounts[INS_ISSUE_BASE_ACC_POS].lamports) == 0) {
        createTokenBaseAccount(
                ins,
                &ins->accounts[INS_ISSUE_BASE_ACC_POS],
                &ins->accounts[RENT_ACC_POS]);

        *newAccSeed = 0;
    } else {
        if(!SolPubkey_same(ins->accounts[INS_ISSUE_BASE_ACC_POS].owner, ins->programId)) {
            sol_log("invalid init account owner: ");
            sol_log_pubkey(ins->accounts[INS_ISSUE_BASE_ACC_POS].owner);
            sol_log("of account: ");
            sol_log_pubkey(ins->accounts[INS_ISSUE_BASE_ACC_POS].key);
            return false;
        } else {
            uint64_t *currentSeed = (uint64_t *)ins->accounts[INS_ISSUE_BASE_ACC_POS].data;
            *currentSeed += 1;
            *newAccSeed = *currentSeed;
        }
    }

    return true;
}

static uint64_t createNewTokenAccount(
        ERC20TokenInstruction *ins,
        SolAccountInfo *rent,
        uint64_t *newTokenAccSeed) {

    uint8_t bumps = 0;
    SolSignerSeed seeds[] = {
            {.addr = ins->signer->key->x, .len = SIZE_PUBKEY},
            {.addr = (uint8_t *)newTokenAccSeed, .len = sizeof(uint64_t)},
            {.addr = &bumps, .len = SIZE_SOL_BUMPS},
    };
    bumps = getBump(seeds, SOL_ARRAY_SIZE(seeds) - 1, ins->programId, NULL);

    SNSP_INS_CreateAccountData createData = buildCreateData(TOKEN_ACC_SPACE_SIZE, ins->programId, rent);

    return createAccount(
            ins,
            &createData,
            ins->accounts[TOKEN_ACC_POS].key,
            seeds,
            SOL_ARRAY_SIZE(seeds));

}

uint64_t issueProcessor(ERC20TokenInstruction *ins) {
    uint64_t newAccSeed;
    if(!checkInfo(ins, &newAccSeed)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    if(SUCCESS != createNewTokenAccount(ins, &ins->accounts[RENT_ACC_POS], &newAccSeed)) {
        return ERROR_INVALID_ACCOUNT_DATA;
    }

    SolAccountInfo tokenAcc = ins->accounts[TOKEN_ACC_POS];
    TokenInfo t = setTokenInfo(tokenAcc.data, ins->data, ins->signer->key->x);

    return createBalanceAccount(
            ins->accounts[TOKEN_ACC_POS].key->x,
            ins->signer->key->x,
            &ins->accounts[INS_ISSUE_BALANCE_ACC_POS],
            ins,
            &ins->accounts[RENT_ACC_POS],
            t.totalSupply
    );
}
