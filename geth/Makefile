# geth build

ARCH=$(shell uname -m)
HOST_ARCH=$(shell uname -m)
TAG=$(shell ./version.sh)
PACKAGE=geth
IMAGE=$(PACKAGE)
BUILDIMAGE=$(PACKAGE)build
OS=alpine
CACHE_FLAG=--no-cache

# restore flag if flag missing, but image in docker
$(shell ./flag.sh $(BUILDIMAGE) $(ARCH) $(TAG))

default: geth-$(TAG)-$(ARCH)

build: $(BUILDIMAGE)-$(ARCH)-$(TAG).flag

run: $(IMAGE)-$(ARCH)-$(TAG).flag

$(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile: Dockerfile.build.$(OS).$(ARCH) Dockerfile.build.$(OS)
	cat Dockerfile.build.$(OS).$(ARCH) Dockerfile.build.$(OS) >$@

$(BUILDIMAGE)-$(ARCH)-$(TAG).flag: $(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile
	docker build --build-arg VERSION=$(TAG) $(CACHE_FLAG) -t $(ARCH)/$(BUILDIMAGE):$(TAG) -f $< .
	docker tag $(ARCH)/$(BUILDIMAGE):$(TAG) ${ARCH}/$(BUILDIMAGE):latest
	touch $@

geth: $(BUILDIMAGE)-$(ARCH)-$(TAG).flag
	docker run --rm -it -v $(PWD):/outside $(ARCH)/$(BUILDIMAGE):$(TAG) /bin/bash -c "cp /usr/local/bin/geth* /outside/"

install: geth
	cp -f $< /usr/local/bin/

geth-$(TAG)-$(ARCH): geth
	mv -f $< $@

publish: geth-$(TAG)-$(ARCH)
	docker run --rm -v $(HOME)/.swift:/.swift -v $(PWD)/$<:/$< $(HOST_ARCH)/swift /bin/bash -c ". /.swift; swift upload --verbose geth-bins $<"

$(IMAGE)-$(ARCH)-$(TAG).dockerfile: Dockerfile.run.$(ARCH) Dockerfile.run
	cat Dockerfile.run.$(ARCH) Dockerfile.run >$@

$(IMAGE)-$(ARCH)-$(TAG).flag: $(IMAGE)-$(ARCH)-$(TAG).dockerfile geth
	docker build $(CACHE_FLAG) -t $(ARCH)/$(IMAGE):$(TAG) -f $< .
	docker tag $(ARCH)/$(IMAGE):$(TAG) $(ARCH)/$(IMAGE):latest
	touch $@

clean:
	rm -rf *.flag *.dockerfile geth geth-$(TAG)-$(ARCH)

distclean: clean

dockerclean:
	docker rmi $(ARCH)/$(BUILDIMAGE):latest $(ARCH)/$(BUILDIMAGE):$(TAG) || true
	docker rmi $(ARCH)/$(IMAGE):latest $(ARCH)/$(IMAGE):$(TAG) || true

realclean: distclean dockerclean
	docker images -f dangling=true -q | xargs docker rmi || true

