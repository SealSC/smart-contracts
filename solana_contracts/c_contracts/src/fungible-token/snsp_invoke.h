#pragma once

#include "sol_structs.h"

#define SNSP_INS_ID_LEN 4
#define SNSP_INS_DATA_LEN(dataType) (SNSP_INS_ID_LEN + sizeof(dataType))

typedef enum {
    SNSP_INS_CreateAccount = 0,
    SNSP_INS_Assign,
    SNSP_INS_Transfer,
    SNSP_INS_CreateAccountWithSeed,
    SNSP_INS_AdvanceNonceAccount,
    SNSP_INS_WithdrawNonceAccount,
    SNSP_INS_InitializeNonceAccount,
    SNSP_INS_AuthorizeNonceAccount,
    SNSP_INS_Allocate,
    SNSP_INS_AllocateWithSeed,
    SNSP_INS_AssignWithSeed,
    SNSP_INS_TransferWithSeed,
    SNSP_INS_End,
} SNSP_INS_ID;

typedef uint32_t SNSP_ID_T;

typedef struct {
    SNSP_ID_T id;
    uint64_t lamports;
    uint64_t space;
    SolPubkey owner;
} SNSP_INS_CreateAccountData;

typedef struct {
    SolPubkey *fundingKey;
    SolPubkey *newAccKey;
    SOL_INVOKE_Param *invokeParam;
    SNSP_INS_CreateAccountData *data;
} SNSP_INS_CreateAccountParam;

typedef struct {
    SNSP_ID_T id;
    SolPubkey newOwner;
} SNSP_INS_AssignParamData;

typedef struct {
    SolPubkey *assignedKey;
    SOL_INVOKE_Param *invokeParam;
    SNSP_INS_AssignParamData *data;
} SNSP_INS_AssignParam;

uint64_t SNSPCreateAccountInvoke(SNSP_INS_CreateAccountParam *param);
uint64_t SNSPAssignInvoke(SNSP_INS_AssignParam *param);
