# Override IMAGE to avoid gh/network dependency:
#   make build IMAGE=ghcr.io/myorg/myrepo
IMAGE        ?= ghcr.io/$(shell gh api user -q .login 2>/dev/null | tr 'A-Z' 'a-z')/$(shell basename $(shell git rev-parse --show-toplevel) 2>/dev/null)
CUDA_VERSION  = 12.8.1
VERSION_TAG   = cu$(CUDA_VERSION)

.PHONY: check-image build push login all

check-image:
	@case "$(IMAGE)" in \
	  ghcr.io//*|*//*|*/|ghcr.io/) \
	    echo "ERROR: IMAGE is malformed or empty: '$(IMAGE)'"; \
	    echo "       Set explicitly: make build IMAGE=ghcr.io/OWNER/REPO"; \
	    exit 1;; \
	esac

build: check-image
	docker build --platform linux/amd64 \
		-t $(IMAGE):latest \
		-t $(IMAGE):$(VERSION_TAG) .

push: check-image
	docker push $(IMAGE):latest
	docker push $(IMAGE):$(VERSION_TAG)

login:
	echo $$(gh auth token) | docker login ghcr.io -u $$(gh api user -q .login | tr 'A-Z' 'a-z') --password-stdin

all: login build push
