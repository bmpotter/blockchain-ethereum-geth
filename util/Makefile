
ARCH=$(shell uname -m)
BINS=string2hex hex2string
BINARCH=$(BINS:=-$(ARCH))

default: $(BINARCH)

$(BINS): %: %.c
	gcc -static -O2 -o $@ $<

%-$(ARCH): %
	cp -v $< $@

publish: $(BINARCH)
	for bin in $? ; do \
		docker run --rm -v $(HOME)/.swift:/.swift -v $(PWD)/$$bin:/$$bin $(ARCH)/swift /bin/bash -c ". /.swift; swift upload --verbose geth-bins $$bin" ; \
	done

clean:
	rm -rf $(BINS) $(BINARCH)

print-%:
	@echo $* = $($*)

