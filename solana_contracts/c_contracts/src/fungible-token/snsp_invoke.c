#include "sol_runtime_info.h"
#include "snsp_invoke.h"

static inline uint64_t getInstructionDataLen(SNSP_INS_ID id) {
    const uint64_t insLen[SNSP_INS_End] = {
            SNSP_INS_DATA_LEN(SNSP_INS_CreateAccountData),
            SNSP_INS_DATA_LEN(SNSP_INS_AssignParamData),
    };

    return insLen[id];
}

static uint64_t invoke(
        SolAccountMeta *sam,
        uint64_t samLen,
        uint8_t *data,
        uint64_t dataLen,
        SOL_INVOKE_Param *invokeParam
        ) {
    SolInstruction si = {
            .program_id = (SolPubkey *)SolSysKey,
            .accounts = sam,
            .account_len = samLen,
            .data = data,
            .data_len = dataLen
    };

    SolSignerSeeds seeds[] = {
            {
                    .addr = invokeParam->signerSeed,
                    .len = invokeParam->seedLen,
            }
    };

    return sol_invoke_signed(
            &si,
            invokeParam->accounts,
            invokeParam->accNum,
            seeds,
            SOL_ARRAY_SIZE(seeds));
}

uint64_t SNSPCreateAccountInvoke(SNSP_INS_CreateAccountParam *param) {
    SolAccountMeta sam[] = {
            {.is_writable = true, .is_signer = true, .pubkey = param->fundingKey},
            {.is_writable = true, .is_signer = true, .pubkey = param->newAccKey},
    };

    uint64_t dataLen = getInstructionDataLen(SNSP_INS_CreateAccount);
    uint8_t *data = sol_calloc(dataLen, sizeof(uint8_t));
    uint64_t dp = 0;
    *(uint32_t *)(data + dp) = SNSP_INS_CreateAccount;
    dp += sizeof param->data->id;

    *(uint64_t *)(data + dp) = param->data->lamports;
    dp += sizeof param->data->lamports;

    *(uint64_t *)(data + dp) = param->data->space;
    dp += sizeof param->data->space;

    sol_memcpy(data + dp,  param->data->owner.x, SIZE_PUBKEY);

    return invoke(sam, SOL_ARRAY_SIZE(sam), data, dataLen, param->invokeParam);

}

uint64_t SNSPAssignInvoke(SNSP_INS_AssignParam *param) {
    SolAccountMeta sam[] = {
            {.is_writable = true, .is_signer = true, .pubkey = param->assignedKey}
    };
    uint64_t dataLen = getInstructionDataLen(SNSP_INS_Assign);
    uint8_t *data = sol_calloc(dataLen, sizeof(uint8_t));

    uint64_t dp = 0;
    *(uint32_t *)(data + dp) = SNSP_INS_Assign;
    dp += sizeof param->data->id;

    sol_log_64(0,0,0,0,dataLen);
    sol_log_64(0,0,0,0,dp);
    sol_memcpy((data + dp), param->data->newOwner.x, SIZE_PUBKEY);

    return invoke(sam, SOL_ARRAY_SIZE(sam), data, dataLen, param->invokeParam);
}

