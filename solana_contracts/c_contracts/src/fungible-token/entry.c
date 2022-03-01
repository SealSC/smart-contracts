#include "parser.h"
#include "processors.h"

extern uint64_t entrypoint(const uint8_t *input) {
    ERC20TokenInstruction ins;
    sol_log("start get ins");

    uint64_t getInsResult = getInstruction(input, &ins);
    if(SUCCESS != getInsResult) {
        sol_log("get instruction failed");
        return getInsResult;
    }

    if(!checkInstruction(&ins)) {
        return ERROR_INVALID_INSTRUCTION_DATA;
    }

    processor p = getProcessor(ins.id);
    if(p == NULL) {
        sol_log("not supported instruction: ");
        seal_sol_log_64(ins.id);
        return ERROR_INVALID_INSTRUCTION_DATA;
    }

    return p(&ins);
}
