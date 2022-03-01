#pragma once

#include <solana_sdk.h>

#define ACCOUNT_STORAGE_OVERHEAD 128

extern const uint8_t SolRentKey[SIZE_PUBKEY];
extern const uint8_t SolSysKey[SIZE_PUBKEY];
extern bool isTheKey(uint8_t *k, const uint8_t *t);

#define isRentKey(k) isTheKey((k), SolRentKey)
#define isSysKey(k) isTheKey((k), SolSysKey)
