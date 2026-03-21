IMAGE = ghcr.io/prgckwb/kaggle-gpu-image
TAG   = latest

build:
	docker build --platform linux/amd64 -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)

login:
	echo $$(gh auth token) | docker login ghcr.io -u prgckwb --password-stdin

all: login build push
