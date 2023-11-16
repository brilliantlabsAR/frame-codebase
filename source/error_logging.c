/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
 *
 * ISC Licence
 *
 * Copyright © 2023 Brilliant Labs Ltd.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#include "error_logging.h"
#include "nrfx_log.h"
#include "nrf_error.h"

static const char *lookup_error_code(uint32_t error_code)
{
    switch (error_code)
    {
    case NRFX_SUCCESS:
        return "NRFX_SUCCESS";

    case NRFX_ERROR_INTERNAL:
        return "NRFX_ERROR_INTERNAL";

    case NRFX_ERROR_NO_MEM:
        return "NRFX_ERROR_NO_MEM";

    case NRFX_ERROR_NOT_SUPPORTED:
        return "NRFX_ERROR_NOT_SUPPORTED";

    case NRFX_ERROR_INVALID_PARAM:
        return "NRFX_ERROR_INVALID_PARAM";

    case NRFX_ERROR_INVALID_STATE:
        return "NRFX_ERROR_INVALID_STATE";

    case NRFX_ERROR_INVALID_LENGTH:
        return "NRFX_ERROR_INVALID_LENGTH";

    case NRFX_ERROR_TIMEOUT:
        return "NRFX_ERROR_TIMEOUT";

    case NRFX_ERROR_FORBIDDEN:
        return "NRFX_ERROR_FORBIDDEN";

    case NRFX_ERROR_NULL:
        return "NRFX_ERROR_NULL";

    case NRFX_ERROR_INVALID_ADDR:
        return "NRFX_ERROR_INVALID_ADDR";

    case NRFX_ERROR_BUSY:
        return "NRFX_ERROR_BUSY";

    case NRFX_ERROR_ALREADY_INITIALIZED:
        return "NRFX_ERROR_ALREADY_INITIALIZED";

    case NRFX_ERROR_DRV_TWI_ERR_OVERRUN:
        return "NRFX_ERROR_DRV_TWI_ERR_OVERRUN";

    case NRFX_ERROR_DRV_TWI_ERR_ANACK:
        return "NRFX_ERROR_DRV_TWI_ERR_ANACK";

    case NRFX_ERROR_DRV_TWI_ERR_DNACK:
        return "NRFX_ERROR_DRV_TWI_ERR_DNACK";

    case NRF_ERROR_SVC_HANDLER_MISSING:
        return "NRF_ERROR_SVC_HANDLER_MISSING";

    case NRF_ERROR_SOFTDEVICE_NOT_ENABLED:
        return "NRF_ERROR_SOFTDEVICE_NOT_ENABLED";

    case NRF_ERROR_INTERNAL:
        return "NRF_ERROR_INTERNAL";

    case NRF_ERROR_NO_MEM:
        return "NRF_ERROR_NO_MEM";

    case NRF_ERROR_NOT_FOUND:
        return "NRF_ERROR_NOT_FOUND";

    case NRF_ERROR_NOT_SUPPORTED:
        return "NRF_ERROR_NOT_SUPPORTED";

    case NRF_ERROR_INVALID_PARAM:
        return "NRF_ERROR_INVALID_PARAM";

    case NRF_ERROR_INVALID_STATE:
        return "NRF_ERROR_INVALID_STATE";

    case NRF_ERROR_INVALID_LENGTH:
        return "NRF_ERROR_INVALID_LENGTH";

    case NRF_ERROR_INVALID_FLAGS:
        return "NRF_ERROR_INVALID_FLAGS";

    case NRF_ERROR_INVALID_DATA:
        return "NRF_ERROR_INVALID_DATA";

    case NRF_ERROR_DATA_SIZE:
        return "NRF_ERROR_DATA_SIZE";

    case NRF_ERROR_TIMEOUT:
        return "NRF_ERROR_TIMEOUT";

    case NRF_ERROR_NULL:
        return "NRF_ERROR_NULL";

    case NRF_ERROR_FORBIDDEN:
        return "NRF_ERROR_FORBIDDEN";

    case NRF_ERROR_INVALID_ADDR:
        return "NRF_ERROR_INVALID_ADDR";

    case NRF_ERROR_BUSY:
        return "NRF_ERROR_BUSY";

    case NRF_ERROR_CONN_COUNT:
        return "NRF_ERROR_CONN_COUNT";

    case NRF_ERROR_RESOURCES:
        return "NRF_ERROR_RESOURCES";

    default:
        return "UNKNOWN_ERROR";
    }
}

void _check_error(nrfx_err_t error_code, const char *file, const int line)
{
    if (0x00000FFF & (error_code))
    {
        if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
        {
            LOG("Crashed at %s:%u - %s",
                file,
                line,
                lookup_error_code(error_code));

            __BKPT();
        }
        NVIC_SystemReset();
    }
}

void _error_with_message(const char *message, const char *file, const int line)
{
    if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
    {
        LOG("Crashed at %s:%u - %s", file, line, message);

        __BKPT();
    }
    NVIC_SystemReset();
}

typedef struct HardFault_stack
{
    uint32_t r0;
    uint32_t r1;
    uint32_t r2;
    uint32_t r3;
    uint32_t r12;
    uint32_t lr;
    uint32_t pc;
    uint32_t psr;
} HardFault_stack_t;

void print_hardfault(uint32_t *p_stack_address)
{
    HardFault_stack_t *p_stack = (HardFault_stack_t *)p_stack_address;
    static const char *cfsr_msgs[] = {
        [0] = "The processor has attempted to execute an undefined instruction",
        [1] = "The processor attempted a load or store at a location that does not permit the operation",
        [2] = NULL,
        [3] = "Unstack for an exception return has caused one or more access violations",
        [4] = "Stacking for an exception entry has caused one or more access violations",
        [5] = "A MemManage fault occurred during floating-point lazy state preservation",
        [6] = NULL,
        [7] = NULL,
        [8] = "Instruction bus error",
        [9] = "Data bus error (PC value stacked for the exception return points to the instruction that caused the fault)",
        [10] = "Data bus error (return address in the stack frame is not related to the instruction that caused the error)",
        [11] = "Unstack for an exception return has caused one or more BusFaults",
        [12] = "Stacking for an exception entry has caused one or more BusFaults",
        [13] = "A bus fault occurred during floating-point lazy state preservation",
        [14] = NULL,
        [15] = NULL,
        [16] = "The processor has attempted to execute an undefined instruction",
        [17] = "The processor has attempted to execute an instruction that makes illegal use of the EPSR",
        [18] = "The processor has attempted an illegal load of EXC_RETURN to the PC, as a result of an invalid context, or an invalid EXC_RETURN value",
        [19] = "The processor has attempted to access a coprocessor",
        [20] = NULL,
        [21] = NULL,
        [22] = NULL,
        [23] = NULL,
        [24] = "The processor has made an unaligned memory access",
        [25] = "The processor has executed an SDIV or UDIV instruction with a divisor of 0",
    };

    uint32_t cfsr = SCB->CFSR;

    if (p_stack != NULL)
    {
        LOG("Hardfault at PC = 0x%08lX", p_stack->pc);
        LOG("R0  = 0x%08lX", p_stack->r0);
        LOG("R1  = 0x%08lX", p_stack->r1);
        LOG("R2  = 0x%08lX", p_stack->r2);
        LOG("R3  = 0x%08lX", p_stack->r3);
        LOG("R12 = 0x%08lX", p_stack->r12);
        LOG("LR  = 0x%08lX", p_stack->lr);
        LOG("PSR = 0x%08lX", p_stack->psr);
    }
    else
    {
        LOG("Hardfault due to stack pointer outside of stack area");
    }

    if (SCB->HFSR & SCB_HFSR_VECTTBL_Msk)
    {
        LOG("BusFault on a vector table read during exception processing");
    }

    for (uint32_t i = 0; i < sizeof(cfsr_msgs) / sizeof(cfsr_msgs[0]); i++)
    {
        if (((cfsr & (1 << i)) != 0) && (cfsr_msgs[i] != NULL))
        {
            LOG("%s", cfsr_msgs[i]);
        }
    }

    if (cfsr & (1 << (0 + 7)))
    {
        LOG("MemManage fault at address: 0x%08lX", SCB->MMFAR);
    }

    if (cfsr & (1 << (8 + 7)))
    {
        LOG("Bus fault at address: 0x%08lX", SCB->BFAR);
    }

    if (CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk)
    {
        __BKPT();
    }

    NVIC_SystemReset();
}

void HardFault_Handler(void)
{
    __ASM volatile(
        "   tst lr, #4                       \n"

        /* PSP is quite simple and does not require additional handler */
        "   itt ne                           \n"
        "   mrsne r0, psp                    \n"
        /* Jump to the handler, do not store LR - returning from handler just exits exception */
        "   bne  HardFault_Handler_Continue  \n"

        /* Processing MSP requires stack checking */
        "   mrs r0, msp                      \n"

        "   ldr   r1, =__stack_top           \n"
        "   ldr   r2, =__stack_bottom           \n"

        /* MSP is in the range of the stack area */
        "   cmp   r0, r1                     \n"
        "   bhi   HardFault_MoveSP           \n"
        "   cmp   r0, r2                     \n"
        "   bhi   HardFault_Handler_Continue \n"

        "HardFault_MoveSP:                   \n"
        "   mov   sp, r1                     \n"
        "   mov   r0, #0                     \n"

        "HardFault_Handler_Continue:         \n"
        "   ldr r3, =%0                      \n"
        "   bx r3                            \n"
        "   .ltorg                           \n"
        : : "X"(print_hardfault));
}