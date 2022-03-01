#include "processors.h"

extern uint64_t issueProcessor(ERC20TokenInstruction* ins);
extern uint64_t transferProcessor(ERC20TokenInstruction* ins);
extern uint64_t approveProcessor(ERC20TokenInstruction* ins);
extern uint64_t transferFromProcessor(ERC20TokenInstruction* ins);
extern uint64_t mintProcessor(ERC20TokenInstruction* ins);
extern uint64_t burnProcessor(ERC20TokenInstruction* ins);

static bool checkAccountNum(uint8_t id, uint8_t num) {
    uint8_t numRequired[INS_ID_ENUM_END] = {
            INS_ISSUE_ACC_END,
            INS_TRANSFER_ACC_END,
            INS_APPROVE_ACC_END,
            INS_TRANSFER_FROM_ACC_END,
            INS_MINT_ACC_END,
            INS_BURN_ACC_END
    };

    return numRequired[id] == num;
}

bool checkInstruction(ERC20TokenInstruction *ins) {
    if(ins->id >= INS_ID_ENUM_END) {
        sol_log("invalid instruction id");
        return false;
    }

    if(!checkAccountNum(ins->id, ins->accNum)) {
        sol_log("invalid instruction account number");
        return false;
    }

    return true;
}

processor getProcessor(uint8_t id) {

    switch (id) {
        case INS_ID_ISSUE:
            return issueProcessor;
        case INS_ID_TRANSFER:
            return transferProcessor;
        case INS_ID_APPROVE:
            return approveProcessor;
        case INS_ID_TRANSFER_FROM:
            return transferFromProcessor;
        case INS_ID_MINT:
            return mintProcessor;
        case INS_ID_BURN:
            return burnProcessor;
    }

    return NULL;
}