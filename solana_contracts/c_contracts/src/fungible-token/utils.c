#include "utils.h"

uint64_t exemptionFee(SolRent *rent, uint64_t space) {
    double threshold = *(double*)rent->exemption_threshold;
    return (uint64_t) (ACCOUNT_STORAGE_OVERHEAD + space) * rent->lamports_per_byte_year * (uint64_t)threshold;
}

uint8_t getBump(SolSignerSeed *seeds, uint64_t seedLen, SolPubkey *programId, SolPubkey *newAddr) {
    SolPubkey k;
    if(newAddr == NULL) {
        newAddr = &k;
    }

    uint8_t bumps = 0;
    sol_try_find_program_address(
            seeds,
            seedLen,
            programId,
            newAddr,
            &bumps);
    return bumps;
}

uint64_t createAccount(
        ERC20TokenInstruction *ins,
        SNSP_INS_CreateAccountData *data,
        SolPubkey *newAccKey,
        SolSignerSeed *singerSeed,
        uint64_t signerSeedLen
) {

    SOL_INVOKE_Param invokeParam = {
            .accounts = ins->accounts,
            .accNum = ins->accNum,
            .signerSeed = singerSeed,
            .seedLen = signerSeedLen,
    };

    SNSP_INS_CreateAccountParam param = {
            .fundingKey = ins->signer->key,
            .newAccKey = newAccKey,
            .invokeParam = &invokeParam,
            .data = data,
    };

    return SNSPCreateAccountInvoke(&param);
}

uint64_t assignAccount(
        ERC20TokenInstruction *ins,
        SNSP_INS_AssignParamData *data,
        SolPubkey *assignedKey,
        SolSignerSeed *singerSeed,
        uint64_t signerSeedLen
        ) {
    SOL_INVOKE_Param invokeParam = {
            .accounts = ins->accounts,
            .accNum = ins->accNum,
            .signerSeed = singerSeed,
            .seedLen = signerSeedLen,
    };

    SNSP_INS_AssignParam param = {
            .assignedKey = assignedKey,
            .invokeParam = &invokeParam,
            .data = data,
    };

    return SNSPAssignInvoke(&param);
}

SNSP_INS_CreateAccountData buildCreateData(uint64_t space, SolPubkey *programId, SolAccountInfo *rent) {
    uint64_t fee = exemptionFee((SolRent *)rent->data, space);

    SNSP_INS_CreateAccountData data = {
            .id = SNSP_INS_CreateAccount,
            .lamports = fee,
            .space = space,
            .owner = *programId
    };

    return data;
}

NewAccountParams getBalanceAccountParam(
        uint8_t *tokenAccKey,
        uint8_t *userAccKey,
        SolPubkey *programId,
        SolPubkey *newKey) {

    NewAccountParams params = {};

    const uint64_t seedsLen = 3;
    params.bumps = 0;
    SolSignerSeed *seeds = sol_calloc(seedsLen, sizeof (SolSignerSeed));

    seeds[0].addr = tokenAccKey;
    seeds[0].len = SIZE_PUBKEY;

    seeds[1].addr = userAccKey;
    seeds[1].len = SIZE_PUBKEY;

    seeds[2].addr = &params.bumps;
    seeds[2].len = SIZE_SOL_BUMPS;

    params.seeds = seeds;
    params.seedLen = seedsLen;

    params.bumps = getBump(seeds, seedsLen - 1, programId, newKey);

    return params;
}


NewAccountParams getApproveAccountParam(
        uint8_t *tokenAccKey,
        uint8_t *spenderAccKey,
        uint8_t *ownerAccKey,
        SolPubkey *programId,
        SolPubkey *newKey) {

    NewAccountParams params = {};

    const uint64_t seedsLen = 4;
    params.bumps = 0;
    SolSignerSeed *seeds = sol_calloc(sizeof(SolSignerSeed), seedsLen);
    seeds[0].addr = tokenAccKey;
    seeds[0].len = SIZE_PUBKEY;

    seeds[1].addr = spenderAccKey;
    seeds[1].len = SIZE_PUBKEY;

    seeds[2].addr = ownerAccKey;
    seeds[2].len = SIZE_PUBKEY;

    seeds[3].addr = &params.bumps;
    seeds[3].len = SIZE_SOL_BUMPS;

    params.seeds = seeds;
    params.seedLen = seedsLen;
    params.bumps = getBump(seeds, seedsLen - 1, programId, newKey);

    return params;
}

uint64_t createBalanceAccount(
        uint8_t *tokenAccKey,
        uint8_t *userAccKey,
        SolAccountInfo *balanceAcc,
        ERC20TokenInstruction *ins,
        SolAccountInfo *rent,
        uint64_t initAmount) {

    uint64_t ret;
    NewAccountParams param = getBalanceAccountParam(tokenAccKey, userAccKey, ins->programId, NULL);

    SNSP_INS_CreateAccountData createData = buildCreateData(TOKEN_BALANCE_SIZE, ins->programId, rent);

    ret = createAccount(ins, &createData, balanceAcc->key, param.seeds, param.seedLen);
    if(SUCCESS != ret) {
        return ret;
    }

    sol_memcpy(balanceAcc->data, (uint8_t *) &initAmount, sizeof(uint64_t));
    sol_memcpy(balanceAcc->data + sizeof(uint64_t), userAccKey, SIZE_PUBKEY);
    return SUCCESS;
}

uint64_t createApproveAccount(
        uint8_t *tokenAccKey,
        uint8_t *spenderAccKey,
        uint8_t *ownerAccKey,
        SolAccountInfo *approveAccount,
        ERC20TokenInstruction *ins,
        SolAccountInfo *rent,
        uint64_t approveAmount) {
    sol_log_pubkey(approveAccount->key);

    uint64_t ret;
    NewAccountParams param = getApproveAccountParam(tokenAccKey, spenderAccKey, ownerAccKey, ins->programId, NULL);

    sol_log("1");
    SNSP_INS_CreateAccountData createData = buildCreateData(APPROVE_INFO_SIZE, ins->programId, rent);
    sol_log("2");

    ret = createAccount(ins, &createData, approveAccount->key, param.seeds, param.seedLen);
    sol_log("3");

    if(SUCCESS != ret) {
        return ret;
    }

    sol_memcpy(approveAccount->data, (uint8_t*) &approveAmount, sizeof(uint64_t));
    return SUCCESS;
}

void setTokenTotalSupply(uint8_t* tokenBuffer, uint64_t newAmount) {
    sol_memcpy(tokenBuffer + NAME_SIZE + SYMBOL_SIZE, (uint8_t*)&newAmount, sizeof(uint64_t));
}

TokenInfo setTokenInfo(uint8_t *dst, uint8_t const *src, uint8_t const *creator) {
    uint64_t pos = 0;
    TokenInfo t = {};

    sol_memcpy(dst + pos, src + pos, NAME_SIZE);
    sol_memcpy(t.name, src + pos, NAME_SIZE);
    pos += NAME_SIZE;

    sol_memcpy(dst + pos, src + pos, SYMBOL_SIZE);
    sol_memcpy(t.symbol, src + pos, SYMBOL_SIZE);
    pos += SYMBOL_SIZE;

    sol_memcpy(dst + pos, src + pos, TOTAL_SUPPLY_SIZE);
    t.totalSupply = *(uint64_t *)(src + pos);

    pos += TOTAL_SUPPLY_SIZE;

    sol_memcpy(dst + pos, src + pos, DECIMALS_SIZE);
    t.decimals = *(src + pos);
    pos += DECIMALS_SIZE;

    sol_memcpy(dst + pos, src + pos, MINTABLE_FLAG_SIZE);
    t.mintable = *(src + pos);
    pos += MINTABLE_FLAG_SIZE;

    sol_memcpy(dst + pos, src + pos, BURNER_FLAG_SIZE);
    t.burnable = *(src + pos);
    pos += BURNER_FLAG_SIZE;

    sol_memcpy(dst + pos, creator, CREATOR_SIZE);

    return t;
}

TokenInfo getTokenInfo(uint8_t *data) {
    TokenInfo t = {};

    uint64_t pos = 0;
    sol_memcpy(t.name, data + pos, NAME_SIZE);
    pos += NAME_SIZE;

    sol_memcpy(t.symbol, data + pos, SYMBOL_SIZE);
    pos += SYMBOL_SIZE;

    t.totalSupply = *(uint64_t*)(data + pos);
    pos += TOTAL_SUPPLY_SIZE;

    t.decimals = *(data + pos);
    pos += DECIMALS_SIZE;

    t.mintable = *(data + pos);
    pos += MINTABLE_FLAG_SIZE;

    t.burnable = *(data + pos);
    pos += BURNER_FLAG_SIZE;

    sol_memcpy(t.creator.x, data + pos, CREATOR_SIZE);

    return t;
}

TokenBalance getBalance(SolAccountInfo *acc) {
    TokenBalance t = {};
    t.amount = *(uint64_t*)acc->data;
    sol_memcpy(t.owner.x, acc->data + sizeof(uint64_t), SIZE_PUBKEY);

    return t;
}

TokenBalance setBalanceOf(SolAccountInfo *acc, uint64_t newBalance) {
    sol_memcpy(acc->data, (uint8_t*) &newBalance, sizeof(uint64_t));
    return getBalance(acc);
}


bool transfer(SolAccountInfo *from, SolAccountInfo *to, uint64_t amount) {
    TokenBalance fb = getBalance(from);
    TokenBalance tb = getBalance(to);

    if(fb.amount < amount) {
        sol_log("insufficient balance");
        return false;
    }

    setBalanceOf(from, fb.amount - amount);
    setBalanceOf(to, tb.amount + amount);

    return true;
}
