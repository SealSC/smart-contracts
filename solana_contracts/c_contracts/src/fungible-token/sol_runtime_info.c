#include <solana_sdk.h>

const uint8_t SolRentKey[SIZE_PUBKEY] = {
        6, 167, 213, 23,
        25, 44, 92, 81,
        33, 140, 201, 76,
        61, 74, 241, 127,
        88, 218, 238, 8,
        155, 161, 253, 68,
        227, 219, 217, 138,
        0, 0, 0, 0
};

const uint8_t SolSysKey[SIZE_PUBKEY] = {0,};

bool isTheKey(uint8_t *k, const uint8_t *t) {
    return 0 == sol_memcmp(k, t,SIZE_PUBKEY);
}
