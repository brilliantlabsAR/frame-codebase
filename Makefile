#
# This file is a part https://github.com/brilliantlabsAR/frame-micropython
#
# Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
#              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
#              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
#
# ISC Licence
#
# Copyright © 2023 Brilliant Labs Ltd.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#

# Use date and time as build version "vYY.DDD.HHMM". := forces evaluation once
BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# C source files
APPLICATION_CORE_C_FILES += application_core/main.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_gpiote.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_qspi.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_systick.c
APPLICATION_CORE_C_FILES += nrfx/mdk/gcc_startup_nrf5340_application.S
APPLICATION_CORE_C_FILES += nrfx/mdk/system_nrf5340_application.c

# NETWORK_CORE_C_FILES += TODO add module files
# NETWORK_CORE_C_FILES += TODO add micropython math libraries
NETWORK_CORE_C_FILES += network_core/main.c
NETWORK_CORE_C_FILES += network_core/micropython_modules/device.c
NETWORK_CORE_C_FILES += network_core/micropython/py/argcheck.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmarm.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmbase.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmthumb.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmx64.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmx86.c
NETWORK_CORE_C_FILES += network_core/micropython/py/asmxtensa.c
NETWORK_CORE_C_FILES += network_core/micropython/py/bc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/binary.c
NETWORK_CORE_C_FILES += network_core/micropython/py/builtinevex.c
NETWORK_CORE_C_FILES += network_core/micropython/py/builtinhelp.c
NETWORK_CORE_C_FILES += network_core/micropython/py/builtinimport.c
NETWORK_CORE_C_FILES += network_core/micropython/py/compile.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitbc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitcommon.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitglue.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitinlinethumb.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitinlinextensa.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnarm.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnthumb.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnx64.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnx86.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnxtensa.c
NETWORK_CORE_C_FILES += network_core/micropython/py/emitnxtensawin.c
NETWORK_CORE_C_FILES += network_core/micropython/py/formatfloat.c
NETWORK_CORE_C_FILES += network_core/micropython/py/frozenmod.c
NETWORK_CORE_C_FILES += network_core/micropython/py/gc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/lexer.c
NETWORK_CORE_C_FILES += network_core/micropython/py/malloc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/map.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modarray.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modbuiltins.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modcmath.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modcollections.c
NETWORK_CORE_C_FILES += network_core/micropython/py/moderrno.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modgc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modio.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modmath.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modmicropython.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modstruct.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modsys.c
NETWORK_CORE_C_FILES += network_core/micropython/py/modthread.c
NETWORK_CORE_C_FILES += network_core/micropython/py/mpprint.c
NETWORK_CORE_C_FILES += network_core/micropython/py/mpstate.c
NETWORK_CORE_C_FILES += network_core/micropython/py/mpz.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nativeglue.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlr.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlraarch64.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrmips.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrpowerpc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrsetjmp.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrthumb.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrx64.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrx86.c
NETWORK_CORE_C_FILES += network_core/micropython/py/nlrxtensa.c
NETWORK_CORE_C_FILES += network_core/micropython/py/obj.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objarray.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objattrtuple.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objbool.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objboundmeth.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objcell.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objclosure.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objcomplex.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objdeque.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objdict.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objenumerate.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objexcept.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objfilter.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objfloat.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objfun.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objgenerator.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objgetitemiter.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objint_longlong.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objint_mpz.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objint.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objlist.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objmap.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objmodule.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objnamedtuple.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objnone.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objobject.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objpolyiter.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objproperty.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objrange.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objreversed.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objset.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objsingleton.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objslice.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objstr.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objstringio.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objstrunicode.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objtuple.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objtype.c
NETWORK_CORE_C_FILES += network_core/micropython/py/objzip.c
NETWORK_CORE_C_FILES += network_core/micropython/py/opmethods.c
NETWORK_CORE_C_FILES += network_core/micropython/py/pairheap.c
NETWORK_CORE_C_FILES += network_core/micropython/py/parse.c
NETWORK_CORE_C_FILES += network_core/micropython/py/parsenum.c
NETWORK_CORE_C_FILES += network_core/micropython/py/parsenumbase.c
NETWORK_CORE_C_FILES += network_core/micropython/py/persistentcode.c
NETWORK_CORE_C_FILES += network_core/micropython/py/profile.c
NETWORK_CORE_C_FILES += network_core/micropython/py/pystack.c
NETWORK_CORE_C_FILES += network_core/micropython/py/qstr.c
NETWORK_CORE_C_FILES += network_core/micropython/py/reader.c
NETWORK_CORE_C_FILES += network_core/micropython/py/repl.c
NETWORK_CORE_C_FILES += network_core/micropython/py/ringbuf.c
NETWORK_CORE_C_FILES += network_core/micropython/py/runtime_utils.c
NETWORK_CORE_C_FILES += network_core/micropython/py/runtime.c
NETWORK_CORE_C_FILES += network_core/micropython/py/scheduler.c
NETWORK_CORE_C_FILES += network_core/micropython/py/scope.c
NETWORK_CORE_C_FILES += network_core/micropython/py/sequence.c
NETWORK_CORE_C_FILES += network_core/micropython/py/showbc.c
NETWORK_CORE_C_FILES += network_core/micropython/py/smallint.c
NETWORK_CORE_C_FILES += network_core/micropython/py/stackctrl.c
NETWORK_CORE_C_FILES += network_core/micropython/py/stream.c
NETWORK_CORE_C_FILES += network_core/micropython/py/unicode.c
NETWORK_CORE_C_FILES += network_core/micropython/py/vm.c
NETWORK_CORE_C_FILES += network_core/micropython/py/vstr.c
NETWORK_CORE_C_FILES += network_core/micropython/py/warning.c
NETWORK_CORE_C_FILES += network_core/micropython/shared/readline/readline.c
NETWORK_CORE_C_FILES += network_core/micropython/shared/runtime/gchelper_generic.c
NETWORK_CORE_C_FILES += network_core/micropython/shared/runtime/interrupt_char.c
NETWORK_CORE_C_FILES += network_core/micropython/shared/runtime/pyexec.c
NETWORK_CORE_C_FILES += network_core/mphalport.c
NETWORK_CORE_C_FILES += nrfx/drivers/src/nrfx_rtc.c
NETWORK_CORE_C_FILES += nrfx/drivers/src/nrfx_spim.c
NETWORK_CORE_C_FILES += nrfx/drivers/src/nrfx_twim.c
NETWORK_CORE_C_FILES += nrfx/mdk/gcc_startup_nrf5340_network.S
NETWORK_CORE_C_FILES += nrfx/mdk/system_nrf5340_network.c
NETWORK_CORE_C_FILES += segger/SEGGER_RTT_printf.c
NETWORK_CORE_C_FILES += segger/SEGGER_RTT.c

SHARED_C_FILES += error_helpers.c
SHARED_C_FILES += interprocessor_messaging.c
SHARED_C_FILES += nrfx/drivers/src/nrfx_ipc.c
SHARED_C_FILES += nrfx/helpers/nrfx_flag32_allocator.c

# Header file paths
APPLICATION_CORE_FLAGS += -Iapplication_core

NETWORK_CORE_FLAGS += -Inetwork_core
NETWORK_CORE_FLAGS += -Inetwork_core/micropython
NETWORK_CORE_FLAGS += -Inetwork_core/micropython_generated
NETWORK_CORE_FLAGS += -Inetwork_core/micropython_modules

SHARED_FLAGS += -I.
SHARED_FLAGS += -Icmsis/CMSIS/Core/Include
SHARED_FLAGS += -Inrfx
SHARED_FLAGS += -Inrfx/drivers/include
SHARED_FLAGS += -Inrfx/hal
SHARED_FLAGS += -Inrfx/mdk
SHARED_FLAGS += -Inrfx/soc
SHARED_FLAGS += -Isegger

# Warnings
SHARED_FLAGS += -Wall
SHARED_FLAGS += -Werror
SHARED_FLAGS += -Wdouble-promotion 
SHARED_FLAGS += -Wfloat-conversion

# Build options and optimizations
APPLICATION_CORE_FLAGS += -mcpu=cortex-m33
APPLICATION_CORE_FLAGS += -mfloat-abi=hard
APPLICATION_CORE_FLAGS += -mfpu=fpv4-sp-d16

NETWORK_CORE_FLAGS += -mcpu=cortex-m33+nodsp
NETWORK_CORE_FLAGS += -mfloat-abi=soft

SHARED_FLAGS += -falign-functions=16
SHARED_FLAGS += -fdata-sections 
SHARED_FLAGS += -ffunction-sections 
SHARED_FLAGS += -flto
SHARED_FLAGS += -fmax-errors=1
SHARED_FLAGS += -fno-common
SHARED_FLAGS += -fno-delete-null-pointer-checks
SHARED_FLAGS += -fno-strict-aliasing
SHARED_FLAGS += -fshort-enums
SHARED_FLAGS += -g3
SHARED_FLAGS += -mabi=aapcs
SHARED_FLAGS += -mcmse
SHARED_FLAGS += -mthumb
SHARED_FLAGS += -Os
SHARED_FLAGS += -std=gnu17

# Preprocessor defines
APPLICATION_CORE_FLAGS += -DNRF5340_XXAA_APPLICATION

NETWORK_CORE_FLAGS += -DNRF5340_XXAA_NETWORK

SHARED_FLAGS += -DBUILD_VERSION='"$(BUILD_VERSION)"'
SHARED_FLAGS += -DGIT_COMMIT='"$(GIT_COMMIT)"'
SHARED_FLAGS += -DNDEBUG

# Linker options & linker script paths
APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

SHARED_FLAGS += --specs=nano.specs
SHARED_FLAGS += -Wl,--gc-sections

# Link required libraries
SHARED_FLAGS += -lm -lc -lnosys -lgcc

all: build/application_core.elf build/network_core.elf
	@arm-none-eabi-objcopy -O ihex build/application_core.elf build/application_core.hex
	@arm-none-eabi-objcopy -O ihex build/network_core.elf build/network_core.hex

build/application_core.elf: $(SHARED_C_FILES) $(APPLICATION_CORE_C_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

# TODO add special opt flags for some of the micropython .c files
build/network_core.elf: $(SHARED_C_FILES) $(NETWORK_CORE_C_FILES) | micropython_generated_headers
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

flash: all
	nrfjprog -q --coprocessor CP_APPLICATION --program build/application_core.hex --sectorerase
	nrfjprog -q --coprocessor CP_NETWORK --program build/network_core.hex --sectorerase
	nrfjprog --reset

clean:
	rm -rf build/
	rm -rf network_core/micropython_generated/

recover:
	nrfjprog --recover

release:
	@echo TODO

include network_core/micropython_related_recipes.mk