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

BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M) # := forces evaluation once
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Micropython related paths for later use
MP_GEN_FOLDER = network_core/micropython_generated/genhdr
MP_PY_FOLDER = network_core/micropython/py

# Source files
SHARED_C_FILES += \
	error_helpers.c \
	interprocessor_messaging.c \
	nrfx/drivers/src/nrfx_ipc.c \
	nrfx/helpers/nrfx_flag32_allocator.c \

APPLICATION_CORE_C_FILES += \
	application_core/main.c \
	nrfx/drivers/src/nrfx_gpiote.c \
	nrfx/drivers/src/nrfx_qspi.c \
	nrfx/drivers/src/nrfx_systick.c \
	nrfx/mdk/gcc_startup_nrf5340_application.S \
	nrfx/mdk/system_nrf5340_application.c \

NETWORK_CORE_C_FILES += \
	network_core/main.c \
	network_core/micropython_modules/device.c \
	network_core/micropython/py/argcheck.c \
	network_core/micropython/py/asmarm.c \
	network_core/micropython/py/asmbase.c \
	network_core/micropython/py/asmthumb.c \
	network_core/micropython/py/asmx64.c \
	network_core/micropython/py/asmx86.c \
	network_core/micropython/py/asmxtensa.c \
	network_core/micropython/py/bc.c \
	network_core/micropython/py/binary.c \
	network_core/micropython/py/builtinevex.c \
	network_core/micropython/py/builtinhelp.c \
	network_core/micropython/py/builtinimport.c \
	network_core/micropython/py/compile.c \
	network_core/micropython/py/emitbc.c \
	network_core/micropython/py/emitcommon.c \
	network_core/micropython/py/emitglue.c \
	network_core/micropython/py/emitinlinethumb.c \
	network_core/micropython/py/emitinlinextensa.c \
	network_core/micropython/py/emitnarm.c \
	network_core/micropython/py/emitnthumb.c \
	network_core/micropython/py/emitnx64.c \
	network_core/micropython/py/emitnx86.c \
	network_core/micropython/py/emitnxtensa.c \
	network_core/micropython/py/emitnxtensawin.c \
	network_core/micropython/py/formatfloat.c \
	network_core/micropython/py/frozenmod.c \
	network_core/micropython/py/lexer.c \
	network_core/micropython/py/malloc.c \
	network_core/micropython/py/map.c \
	network_core/micropython/py/modarray.c \
	network_core/micropython/py/modbuiltins.c \
	network_core/micropython/py/modcmath.c \
	network_core/micropython/py/modcollections.c \
	network_core/micropython/py/moderrno.c \
	network_core/micropython/py/modgc.c \
	network_core/micropython/py/modio.c \
	network_core/micropython/py/modmath.c \
	network_core/micropython/py/modmicropython.c \
	network_core/micropython/py/modstruct.c \
	network_core/micropython/py/modsys.c \
	network_core/micropython/py/modthread.c \
	network_core/micropython/py/mpprint.c \
	network_core/micropython/py/mpstate.c \
	network_core/micropython/py/mpz.c \
	network_core/micropython/py/nativeglue.c \
	network_core/micropython/py/nlr.c \
	network_core/micropython/py/nlraarch64.c \
	network_core/micropython/py/nlrmips.c \
	network_core/micropython/py/nlrpowerpc.c \
	network_core/micropython/py/nlrsetjmp.c \
	network_core/micropython/py/nlrthumb.c \
	network_core/micropython/py/nlrx64.c \
	network_core/micropython/py/nlrx86.c \
	network_core/micropython/py/nlrxtensa.c \
	network_core/micropython/py/obj.c \
	network_core/micropython/py/objarray.c \
	network_core/micropython/py/objattrtuple.c \
	network_core/micropython/py/objbool.c \
	network_core/micropython/py/objboundmeth.c \
	network_core/micropython/py/objcell.c \
	network_core/micropython/py/objclosure.c \
	network_core/micropython/py/objcomplex.c \
	network_core/micropython/py/objdeque.c \
	network_core/micropython/py/objdict.c \
	network_core/micropython/py/objenumerate.c \
	network_core/micropython/py/objexcept.c \
	network_core/micropython/py/objfilter.c \
	network_core/micropython/py/objfloat.c \
	network_core/micropython/py/objfun.c \
	network_core/micropython/py/objgenerator.c \
	network_core/micropython/py/objgetitemiter.c \
	network_core/micropython/py/objint_longlong.c \
	network_core/micropython/py/objint_mpz.c \
	network_core/micropython/py/objint.c \
	network_core/micropython/py/objlist.c \
	network_core/micropython/py/objmap.c \
	network_core/micropython/py/objmodule.c \
	network_core/micropython/py/objnamedtuple.c \
	network_core/micropython/py/objnone.c \
	network_core/micropython/py/objobject.c \
	network_core/micropython/py/objpolyiter.c \
	network_core/micropython/py/objproperty.c \
	network_core/micropython/py/objrange.c \
	network_core/micropython/py/objreversed.c \
	network_core/micropython/py/objset.c \
	network_core/micropython/py/objsingleton.c \
	network_core/micropython/py/objslice.c \
	network_core/micropython/py/objstr.c \
	network_core/micropython/py/objstringio.c \
	network_core/micropython/py/objstrunicode.c \
	network_core/micropython/py/objtuple.c \
	network_core/micropython/py/objtype.c \
	network_core/micropython/py/objzip.c \
	network_core/micropython/py/opmethods.c \
	network_core/micropython/py/pairheap.c \
	network_core/micropython/py/parse.c \
	network_core/micropython/py/parsenum.c \
	network_core/micropython/py/parsenumbase.c \
	network_core/micropython/py/persistentcode.c \
	network_core/micropython/py/profile.c \
	network_core/micropython/py/pystack.c \
	network_core/micropython/py/qstr.c \
	network_core/micropython/py/reader.c \
	network_core/micropython/py/repl.c \
	network_core/micropython/py/ringbuf.c \
	network_core/micropython/py/runtime_utils.c \
	network_core/micropython/py/runtime.c \
	network_core/micropython/py/scheduler.c \
	network_core/micropython/py/scope.c \
	network_core/micropython/py/sequence.c \
	network_core/micropython/py/showbc.c \
	network_core/micropython/py/smallint.c \
	network_core/micropython/py/stackctrl.c \
	network_core/micropython/py/stream.c \
	network_core/micropython/py/unicode.c \
	network_core/micropython/py/vstr.c \
	network_core/micropython/py/warning.c \
	network_core/micropython/shared/readline/readline.c \
	network_core/micropython/shared/runtime/gchelper_generic.c \
	network_core/micropython/shared/runtime/interrupt_char.c \
	network_core/micropython/shared/runtime/pyexec.c \
	network_core/mphalport.c \
	nrfx/drivers/src/nrfx_rtc.c \
	nrfx/drivers/src/nrfx_spim.c \
	nrfx/drivers/src/nrfx_twim.c \
	nrfx/mdk/gcc_startup_nrf5340_network.S \
	nrfx/mdk/system_nrf5340_network.c \
	segger/SEGGER_RTT_printf.c \
	segger/SEGGER_RTT.c \

FROZEN_PYTHON_FILES += \
	network_core/micropython_modules/test.py

# Header file paths
SHARED_FLAGS += \
	-I. \
	-Icmsis/CMSIS/Core/Include \
	-Inrfx \
	-Inrfx/drivers/include \
	-Inrfx/hal \
	-Inrfx/mdk \
	-Inrfx/soc \
	-Isegger \

APPLICATION_CORE_FLAGS += \
	-Iapplication_core \

NETWORK_CORE_FLAGS += \
	-Inetwork_core \
	-Inetwork_core/micropython \
	-Inetwork_core/micropython_generated \
	-Inetwork_core/micropython_modules \

# Warnings
SHARED_FLAGS += \
	-Wall \
	-Werror \
	-Wdouble-promotion  \
	-Wfloat-conversion \

# Build options and optimizations
SHARED_FLAGS += \
	-falign-functions=16 \
	-fdata-sections  \
	-ffunction-sections  \
	-flto \
	-fmax-errors=1 \
	-fno-common \
	-fno-delete-null-pointer-checks \
	-fno-strict-aliasing \
	-fshort-enums \
	-g3 \
	-mabi=aapcs \
	-mcmse \
	-mthumb \
	-Os \
	-std=gnu17 \

APPLICATION_CORE_FLAGS += \
	-mcpu=cortex-m33 \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16

NETWORK_CORE_FLAGS += \
	-mcpu=cortex-m33+nodsp \
	-mfloat-abi=soft

# Preprocessor defines
SHARED_FLAGS += \
	-DBUILD_VERSION='"$(BUILD_VERSION)"' \
	-DGIT_COMMIT='"$(GIT_COMMIT)"' \
	-DNDEBUG \

APPLICATION_CORE_FLAGS += \
	-DNRF5340_XXAA_APPLICATION \

NETWORK_CORE_FLAGS += \
	-DNRF5340_XXAA_NETWORK \

# Linker options
SHARED_FLAGS += \
	--specs=nano.specs \
	-Wl,--gc-sections \

# Linker script paths
APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

# Link required libraries
SHARED_FLAGS += \
	-lm \
	-lc \
	-lnosys \
	-lgcc

all: build/application_core.elf \
	 build/network_core.elf
	@arm-none-eabi-objcopy -O ihex build/application_core.elf build/application_core.hex
	@arm-none-eabi-objcopy -O ihex build/network_core.elf build/network_core.hex
	@arm-none-eabi-size $^

build/application_core.elf: $(SHARED_C_FILES) \
							$(APPLICATION_CORE_C_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^

build/network_core.elf: $(SHARED_C_FILES) \
						$(NETWORK_CORE_C_FILES) \
						| micropython_generated_headers
	@python3 network_core/micropython/tools/makemanifest.py \
		-o "$(MP_GEN_FOLDER)/frozen_content.c" \
		-b "$(MP_GEN_FOLDER)/.." \
		-v "MPY_DIR=network_core/micropython" \
		-v "PORT_DIR=network_core" \
		network_core/micropython_modules/frozen_manifest.py

	@mkdir -p build
	@mkdir -p build/network_core_objects

	@arm-none-eabi-gcc \
		$(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) -O3 \
		-c network_core/micropython/py/gc.c \
		   network_core/micropython/py/vm.c \

	# TODO generate these files in the correct place
	mv gc.o vm.o build/network_core_objects

	@arm-none-eabi-gcc \
		$(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) \
		-o $@ \
		$(MP_GEN_FOLDER)/frozen_content.c \
		build/network_core_objects/gc.o \
		build/network_core_objects/vm.o \
		$^

micropython_generated_headers: $(SHARED_C_FILES) \
							   $(NETWORK_CORE_C_FILES)
	@mkdir -p $(MP_GEN_FOLDER)
	
	@python3 $(MP_PY_FOLDER)/makeversionhdr.py $(MP_GEN_FOLDER)/mpversion.h

	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		pp arm-none-eabi-gcc -E \
		output $(MP_GEN_FOLDER)/qstr.i.last \
		cflags -DNO_QSTR $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) \
		sources $(NETWORK_CORE_C_FILES) \
		dependencies $(MP_PY_FOLDER)/mpconfig.h network_core/mpconfigport.h \
		changed_sources $(NETWORK_CORE_C_FILES)

	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		split root_pointer $(MP_GEN_FOLDER)/qstr.i.last $(MP_GEN_FOLDER)/root_pointer _
	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		cat root_pointer _ $(MP_GEN_FOLDER)/root_pointer $(MP_GEN_FOLDER)/root_pointers.collected
	@python3 $(MP_PY_FOLDER)/make_root_pointers.py \
		$(MP_GEN_FOLDER)/root_pointers.collected > $(MP_GEN_FOLDER)/root_pointers.h

	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		split module $(MP_GEN_FOLDER)/qstr.i.last $(MP_GEN_FOLDER)/module _
	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		cat module _ $(MP_GEN_FOLDER)/module $(MP_GEN_FOLDER)/moduledefs.collected
	@python3 $(MP_PY_FOLDER)/makemoduledefs.py \
		$(MP_GEN_FOLDER)/moduledefs.collected > $(MP_GEN_FOLDER)/moduledefs.h

	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		split compress $(MP_GEN_FOLDER)/qstr.i.last $(MP_GEN_FOLDER)/compress _
	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		cat compress _ $(MP_GEN_FOLDER)/compress $(MP_GEN_FOLDER)/compressed.collected
	@python3 $(MP_PY_FOLDER)/makecompresseddata.py \
		$(MP_GEN_FOLDER)/compressed.collected > $(MP_GEN_FOLDER)/compressed.data.h

	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		split qstr $(MP_GEN_FOLDER)/qstr.i.last $(MP_GEN_FOLDER)/qstr _
	@python3 $(MP_PY_FOLDER)/makeqstrdefs.py \
		cat qstr _ $(MP_GEN_FOLDER)/qstr $(MP_GEN_FOLDER)/qstrdefs.collected.h

	@cat $(MP_PY_FOLDER)/qstrdefs.h $(MP_GEN_FOLDER)/qstrdefs.collected.h \
		| sed 's/^Q(.*)/"&"/' | arm-none-eabi-gcc -E $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) - \
		| sed 's/^\"\(Q(.*)\)\"/\1/' > $(MP_GEN_FOLDER)/qstrdefs.preprocessed.h
	@python3 $(MP_PY_FOLDER)/makeqstrdata.py \
		$(MP_GEN_FOLDER)/qstrdefs.preprocessed.h > $(MP_GEN_FOLDER)/qstrdefs.generated.h

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