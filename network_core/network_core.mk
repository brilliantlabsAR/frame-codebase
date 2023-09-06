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

# Source files
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

# Header file paths
NETWORK_CORE_FLAGS += -Inetwork_core
NETWORK_CORE_FLAGS += -Inetwork_core/micropython
NETWORK_CORE_FLAGS += -Inetwork_core/micropython_generated
NETWORK_CORE_FLAGS += -Inetwork_core/micropython_modules

# Build options and optimizations
NETWORK_CORE_FLAGS += -mcpu=cortex-m33+nodsp
NETWORK_CORE_FLAGS += -mfloat-abi=soft

# Preprocessor defines
NETWORK_CORE_FLAGS += -DNRF5340_XXAA_NETWORK

# Linker script path
NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

# TODO add special opt flags for some of the micropython .c files
build/network_core.elf: $(SHARED_C_FILES) $(NETWORK_CORE_C_FILES) | micropython_generated_headers
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

GENERATED_FOLDER = network_core/micropython_generated/genhdr
MICROPYTHON_PY_FOLDER = network_core/micropython/py

micropython_generated_headers: $(GENERATED_FOLDER)/mpversion.h $(GENERATED_FOLDER)/qstrdefs.generated.h $(GENERATED_FOLDER)/compressed.data.h $(GENERATED_FOLDER)/moduledefs.h $(GENERATED_FOLDER)/root_pointers.h

.PHONY: $(GENERATED_FOLDER)/mpversion.h
$(GENERATED_FOLDER)/mpversion.h: $(GENERATED_FOLDER)
	@python3 $(MICROPYTHON_PY_FOLDER)/makeversionhdr.py $@

$(GENERATED_FOLDER)/qstrdefs.generated.h: $(GENERATED_FOLDER)/qstrdefs.collected.h
	@cat $(MICROPYTHON_PY_FOLDER)/qstrdefs.h $(GENERATED_FOLDER)/qstrdefs.collected.h | sed 's/^Q(.*)/"&"/' | arm-none-eabi-gcc -E $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) - | sed 's/^\"\(Q(.*)\)\"/\1/' > $(GENERATED_FOLDER)/qstrdefs.preprocessed.h
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdata.py $(GENERATED_FOLDER)/qstrdefs.preprocessed.h > $@

$(GENERATED_FOLDER)/compressed.data.h: $(GENERATED_FOLDER)/compressed.collected
	@python3 $(MICROPYTHON_PY_FOLDER)/makecompresseddata.py $< > $@

$(GENERATED_FOLDER)/moduledefs.h: $(GENERATED_FOLDER)/moduledefs.collected
	@python3 $(MICROPYTHON_PY_FOLDER)/makemoduledefs.py $< > $@

$(GENERATED_FOLDER)/root_pointers.h: $(GENERATED_FOLDER)/root_pointers.collected
	@python3 $(MICROPYTHON_PY_FOLDER)/make_root_pointers.py $< > $@

$(GENERATED_FOLDER)/qstrdefs.collected.h: $(GENERATED_FOLDER)/qstr.i.last
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py split qstr $< $(GENERATED_FOLDER)/qstr _
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py cat qstr _ $(GENERATED_FOLDER)/qstr $@

$(GENERATED_FOLDER)/compressed.collected: $(GENERATED_FOLDER)/qstr.i.last
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py split compress $< $(GENERATED_FOLDER)/compress _
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py cat compress _ $(GENERATED_FOLDER)/compress $@

$(GENERATED_FOLDER)/moduledefs.collected: $(GENERATED_FOLDER)/qstr.i.last
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py split module $< $(GENERATED_FOLDER)/module _
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py cat module _ $(GENERATED_FOLDER)/module $@

$(GENERATED_FOLDER)/root_pointers.collected: $(GENERATED_FOLDER)/qstr.i.last
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py split root_pointer $< $(GENERATED_FOLDER)/root_pointer _
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py cat root_pointer _ $(GENERATED_FOLDER)/root_pointer $@

$(GENERATED_FOLDER)/qstr.i.last: $(NETWORK_CORE_C_FILES) | $(GENERATED_FOLDER) 
	@python3 $(MICROPYTHON_PY_FOLDER)/makeqstrdefs.py pp arm-none-eabi-gcc -E output $(GENERATED_FOLDER)/qstr.i.last cflags -DNO_QSTR $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) sources $^ dependencies $(MICROPYTHON_PY_FOLDER)/mpconfig.h network_core/mpconfigport.h changed_sources $?

$(GENERATED_FOLDER):
	@mkdir -p $@