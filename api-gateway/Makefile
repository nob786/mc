.PHONY:	all build build-package build-docker push-docker

all:	build

build:	build-package \
	build-docker \
	push-docker	

SHELL := /bin/bash

build-package:
	#TBD #mvn package
	
build-docker: build-package
	docker build -t gateway-service .
	
#run-docker: stop-docker
#	docker run -d -p 9000:9000 --name gateway gateway-service
#	
#run-docker-compose: stop-docker
#	docker run -d -p 9000:9000 -e SPRING_PROFILES_ACTIVE=compose --name gateway gateway-service
#	
#stop-docker:
#	-docker stop gateway
#	-docker rm gateway
	
push-docker:
	#TBD #docker push public.ecr.aws/eatsabyte/gateway-service
