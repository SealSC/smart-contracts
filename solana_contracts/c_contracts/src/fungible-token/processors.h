#pragma once

#include "instructions.h"

typedef uint64_t (* processor)(ERC20TokenInstruction *);

bool checkInstruction(ERC20TokenInstruction *ins);
processor getProcessor(uint8_t id);
