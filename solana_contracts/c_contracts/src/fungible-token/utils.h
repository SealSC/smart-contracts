#pragma once

#include "sol_structs.h"
#include "sol_runtime_info.h"
#include "snsp_invoke.h"
#include "instructions.h"

extern uint64_t exemptionFee(SolRent *rent, uint64_t space);
extern uint8_t getBump(SolSignerSeed *seeds, uint64_t seedLen, SolPubkey *programId, SolPubkey *newAddr);

extern uint64_t createAccount(
        ERC20TokenInstruction *ins,
        SNSP_INS_CreateAccountData *data,
        SolPubkey *newAccKey,
        SolSignerSeed *singerSeed,
        uint64_t signerSeedLen
);

extern uint64_t assignAccount(
        ERC20TokenInstruction *ins,
        SNSP_INS_AssignParamData *data,
        SolPubkey *assignedKey,
        SolSignerSeed *singerSeed,
        uint64_t signerSeedLen
);

extern SNSP_INS_CreateAccountData buildCreateData(uint64_t space, SolPubkey *programId, SolAccountInfo *rent);


typedef struct {
    SolSignerSeed *seeds;
    uint64_t seedLen;
    uint8_t bumps;
} NewAccountParams;

extern NewAccountParams getApproveAccountParam(
        uint8_t *tokenAccKey,
        uint8_t *spenderAccKey,
        uint8_t *ownerAccKey,
        SolPubkey *programId,
        SolPubkey *newKey);

extern NewAccountParams getBalanceAccountParam(
        uint8_t *tokenAccKey,
        uint8_t *userAccKey,
        SolPubkey *programId,
        SolPubkey *balanceKey);

extern uint64_t createBalanceAccount(
        uint8_t *tokenAccKey,
        uint8_t *userAccKey,
        SolAccountInfo *balanceAcc,
        ERC20TokenInstruction *ins,
        SolAccountInfo *rent,
        uint64_t initAmount);

extern uint64_t createApproveAccount(
        uint8_t *tokenAccKey,
        uint8_t *spenderAccKey,
        uint8_t *ownerAccKey,
        SolAccountInfo *approveAccount,
        ERC20TokenInstruction *ins,
        SolAccountInfo *rent,
        uint64_t approveAmount);

extern TokenInfo setTokenInfo(uint8_t *dst, uint8_t const *src, uint8_t const *creator);
extern TokenInfo getTokenInfo(uint8_t *data);
extern void setTokenTotalSupply(uint8_t* tokenBuffer, uint64_t newAmount);

extern TokenBalance getBalance(SolAccountInfo *acc);
extern bool transfer(SolAccountInfo *from, SolAccountInfo *to, uint64_t amount);
