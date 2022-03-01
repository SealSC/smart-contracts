#pragma once

#include <solana_sdk.h>

typedef struct {
    uint64_t lamports_per_byte_year;
    uint8_t exemption_threshold[8];
    uint8_t burn_percent;
} SolRent;

typedef struct {
    SolAccountInfo *accounts;
    uint64_t accNum;
    SolSignerSeed *signerSeed;
    uint64_t seedLen;
} SOL_INVOKE_Param;
