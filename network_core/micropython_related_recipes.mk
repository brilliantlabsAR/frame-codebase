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