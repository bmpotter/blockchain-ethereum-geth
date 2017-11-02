# geth build

PACKAGE=geth
ARCH=$(shell uname -m)
HOST_ARCH=$(shell uname -m)
TAG=$(shell ./$(PACKAGE)/version.sh)
SUBTAG=-r9
IMAGE=$(PACKAGE)
BUILDIMAGE=$(PACKAGE)build
OS=alpine
CACHE_FLAG=--no-cache
SRC=util/string2hex.c util/hex2string.c
BINS=util/string2hex util/hex2string
BINARCH=$(BINS:=-$(ARCH))
SCRIPTS=scripts/geth.sh scripts/functions scripts/unlock.sh scripts/peerlist.sh scripts/start.sh scripts/globals scripts/handout.sh scripts/blockmon.sh scripts/clean.sh scripts/miner.sh scripts/genesis.sh

# restore flag if flag missing, but image in docker
$(shell ./$(PACKAGE)/flag.sh $(IMAGE) $(ARCH) $(TAG)$(SUBTAG))

default: $(IMAGE)-$(ARCH)-$(TAG)$(SUBTAG).flag

%-$(ARCH): 
	cd util; make $(shell basename $@)

$(PACKAGE)/$(PACKAGE)-$(TAG)-$(ARCH):
	cd $(PACKAGE); make ARCH=$(ARCH) OS=$(OS) TAG=$(TAG)

$(IMAGE)-$(ARCH)-$(TAG)$(SUBTAG).dockerfile: Dockerfile.run.$(OS).$(ARCH) Dockerfile.run.$(OS)
	cat Dockerfile.run.$(OS).$(ARCH) Dockerfile.run.$(OS) >$@

$(IMAGE)-$(ARCH)-$(TAG)$(SUBTAG).flag: $(IMAGE)-$(ARCH)-$(TAG)$(SUBTAG).dockerfile $(BINARCH) $(PACKAGE)/$(PACKAGE)-$(TAG)-$(ARCH) $(SCRIPTS) $(SRC)
	docker build $(CACHE_FLAG) --build-arg ARCH=$(ARCH) --build-arg TAG=$(TAG) --build-arg PACKAGE=$(PACKAGE) -t $(ARCH)/$(IMAGE):$(TAG)$(SUBTAG) -f $< .
	docker tag $(ARCH)/$(IMAGE):$(TAG)$(SUBTAG) $(ARCH)/$(IMAGE):latest
	touch $@

clean:
	rm -rf *.flag $(IMAGE)-$(ARCH)-$(TAG).dockerfile

distclean: clean
	cd util; make ARCH=$(ARCH) clean
	cd $(PACKAGE); make ARCH=$(ARCH) distclean

dockerclean:
	docker rmi $(ARCH)/$(IMAGE):latest $(ARCH)/$(IMAGE):$(TAG)$(SUBTAG) || true

realclean: distclean dockerclean
	docker images -f dangling=true -q | xargs docker rmi || true

