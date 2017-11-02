# golang build

ARCH=$(shell uname -m)
TAG=$(shell ./version.sh)
PACKAGE=golang
IMAGE=$(PACKAGE)
BUILDIMAGE=$(PACKAGE)build
CACHE_FLAG=--no-cache

# restore flag if flag missing, but image in docker
$(shell ./flag.sh $(BUILDIMAGE) $(ARCH) $(TAG))
$(shell ./flag.sh $(BUILD) $(ARCH) $(TAG))

default: run

build: $(BUILDIMAGE)-$(ARCH)-$(TAG).flag

run: $(IMAGE)-$(ARCH)-$(TAG).flag

$(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile: Dockerfile.build.$(ARCH) Dockerfile.build
	cat Dockerfile.build.$(ARCH) Dockerfile.build >$(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile

$(BUILDIMAGE)-$(ARCH)-$(TAG).flag: $(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile
	docker build --build-arg VERSION=$(TAG) $(CACHE_FLAG) -t $(ARCH)/$(BUILDIMAGE):$(TAG) -f $(BUILDIMAGE)-$(ARCH)-$(TAG).dockerfile .
	docker tag $(ARCH)/$(BUILDIMAGE):$(TAG) ${ARCH}/$(BUILDIMAGE):latest
	touch $(BUILDIMAGE)-$(ARCH)-$(TAG).flag

go/VERSION: $(BUILDIMAGE)-$(ARCH)-$(TAG).flag
	mkdir -p go
	docker run --rm -it -v $(PWD)/go:/mygo $(ARCH)/$(BUILDIMAGE):$(TAG) /bin/bash -c "rm -rf /tmp/go/src; cp -va /tmp/go/* /mygo/"

$(IMAGE)-$(ARCH)-$(TAG).dockerfile: Dockerfile.run.$(ARCH) Dockerfile.run
	cat Dockerfile.run.$(ARCH) Dockerfile.run >$(IMAGE)-$(ARCH)-$(TAG).dockerfile

$(IMAGE)-$(ARCH)-$(TAG).flag: $(IMAGE)-$(ARCH)-$(TAG).dockerfile go/VERSION
	docker build $(CACHE_FLAG) -t $(ARCH)/$(IMAGE):$(TAG) -f $(IMAGE)-$(ARCH)-$(TAG).dockerfile .
	docker tag $(ARCH)/$(IMAGE):$(TAG) $(ARCH)/$(IMAGE):latest
	touch $(IMAGE)-$(ARCH)-$(TAG).flag

clean:
	rm -rf *.flag *.dockerfile go

distclean: clean

dockerclean:
	docker rmi $(ARCH)/$(BUILDIMAGE):latest $(ARCH)/$(BUILDIMAGE):$(TAG) || true
	docker rmi $(ARCH)/$(IMAGE):latest $(ARCH)/$(IMAGE):$(TAG) || true

realclean: distclean dockerclean
	docker images -f dangling=true -q | xargs docker rmi

