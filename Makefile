OWNER         = $(shell gh api user -q .login)
REPO          = $(shell basename $(shell git rev-parse --show-toplevel))
IMAGE         = ghcr.io/$(OWNER)/$(REPO)
CUDA_VERSION  = 12.8.1
VERSION_TAG   = cu$(CUDA_VERSION)

build:
	docker build --platform linux/amd64 \
		-t $(IMAGE):latest \
		-t $(IMAGE):$(VERSION_TAG) .

push:
	docker push $(IMAGE):latest
	docker push $(IMAGE):$(VERSION_TAG)

login:
	echo $$(gh auth token) | docker login ghcr.io -u $(OWNER) --password-stdin

all: login build push
