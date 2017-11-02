# swift build

ARCH=$(shell uname -m)
TAG=$(shell ./version.sh)
PACKAGE=swift
IMAGE=$(PACKAGE)
CACHE_FLAG=--no-cache

# restore flag if flag missing, but image in docker
$(shell ./flag.sh $(BUILD) $(ARCH) $(TAG))

default: run

run: $(IMAGE)-$(ARCH)-$(TAG).flag

$(IMAGE)-$(ARCH)-$(TAG).dockerfile: Dockerfile.run.$(ARCH) Dockerfile.run
	cat Dockerfile.run.$(ARCH) Dockerfile.run >$(IMAGE)-$(ARCH)-$(TAG).dockerfile

$(IMAGE)-$(ARCH)-$(TAG).flag: $(IMAGE)-$(ARCH)-$(TAG).dockerfile
	docker build $(CACHE_FLAG) -t $(ARCH)/$(IMAGE):$(TAG) -f $(IMAGE)-$(ARCH)-$(TAG).dockerfile .
	docker tag $(ARCH)/$(IMAGE):$(TAG) $(ARCH)/$(IMAGE):latest
	touch $(IMAGE)-$(ARCH)-$(TAG).flag

clean:
	rm -rf *.flag *.dockerfile

distclean: clean

dockerclean:
	docker rmi $(ARCH)/$(IMAGE):latest $(ARCH)/$(IMAGE):$(TAG) || true

realclean: distclean dockerclean
	docker images -f dangling=true -q | xargs docker rmi

