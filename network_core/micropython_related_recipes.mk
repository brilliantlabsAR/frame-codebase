GENERATED_FOLDER = network_core/micropython_generated
MICROPYTHON_PY_FOLDER = network_core/micropython/py

micropython_generated_headers: $(GENERATED_FOLDER)/mpversion.h $(GENERATED_FOLDER)/qstrdefs.generated.h $(GENERATED_FOLDER)/compressed.data.h $(GENERATED_FOLDER)/moduledefs.h $(GENERATED_FOLDER)/root_pointers.h
	@echo TODO $@

.PHONY: $(GENERATED_FOLDER)/mpversion.h
$(GENERATED_FOLDER)/mpversion.h: $(GENERATED_FOLDER)
	@python3 $(MICROPYTHON_PY_FOLDER)/makeversionhdr.py $@

$(GENERATED_FOLDER)/qstrdefs.generated.h: $(GENERATED_FOLDER)
	@echo TODO $@

$(GENERATED_FOLDER)/compressed.data.h: $(GENERATED_FOLDER)
	@echo TODO $@

$(GENERATED_FOLDER)/moduledefs.h: $(GENERATED_FOLDER)
	@echo TODO $@

$(GENERATED_FOLDER)/root_pointers.h: $(GENERATED_FOLDER)
	@echo TODO $@

$(GENERATED_FOLDER):
	@mkdir -p $@