#include "instructions.h"

#define INS_ID_POS 0
#define DATA_OFFSET 1

bool getSolParameters(const uint8_t *input, SolParameters* params, uint64_t kaCount) {
    if (!sol_deserialize(input, params, kaCount)) {
        return false;
    }

    if(!params->ka[0].is_signer) {
        return false;
    }

    return true;
}

uint64_t getInstruction(const uint8_t *input, ERC20TokenInstruction *ins) {
    uint64_t kaCounts =  *(uint64_t *) input;

    SolAccountInfo *accounts = sol_calloc(kaCounts, sizeof(SolAccountInfo));
    SolParameters params = {.ka = accounts};

    if(!getSolParameters(input, &params, kaCounts)) {
        return ERROR_INVALID_ARGUMENT;
    }

    ins->accNum = kaCounts;
    ins->signer = &params.ka[0];
    ins->accounts = params.ka;
    ins->id = params.data[INS_ID_POS];
    ins->data = params.data + DATA_OFFSET;
    ins->dataLen = params.data_len - DATA_OFFSET; //id field of the instruction was skipped, length reduce 1.
    ins->programId = (SolPubkey *)params.program_id;

    return SUCCESS;
}
