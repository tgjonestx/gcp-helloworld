
IMAGE_NAME := helloworld
PROJECT_NAME ?= flowing-access-184016
ENDPOINTS_KEY=AIzaSyCtCDC0VxCXjKYXzKZTMPbK_Wp_x8Neu6o

# Docker image management: doit, build, tag, push, pull, run, clean
#
doit: build tag push

build:
	docker build -t ${IMAGE_NAME} .

tag:
	docker tag ${IMAGE_NAME} gcr.io/${PROJECT_NAME}/${IMAGE_NAME}

push:
	gcloud docker -- push gcr.io/${PROJECT_NAME}/${IMAGE_NAME}

pull:
	gcloud docker -- pull gcr.io/${PROJECT_NAME}/${IMAGE_NAME}

run:
	docker run -p 8080:8080 ${IMAGE_NAME}

clean:
	-rm -f openapi.yaml container-engine.yaml
	-docker rmi ${IMAGE_NAME}
	-docker rmi gcr.io/${PROJECT_NAME}/${IMAGE_NAME}
	-gcloud container images delete --force-delete-tags gcr.io/${PROJECT_NAME}/${IMAGE_NAME}


#
# Google Cloud Endpoints Management -
#
# Run in this order:
# - deploy
# - get-credentials
# - get-service-id
# - <use Service Configuration id from deploy or get-service-id to update container-engine.yaml>
# - create-service or update-service
# - <wait for get-service-ip to return an external IP>
#
openapi.yaml:
	sed -e 's/#PROJECT_NAME#/${PROJECT_NAME}/g' openapi.in.yaml >openapi.yaml

deploy: openapi.yaml
	gcloud endpoints services deploy openapi.yaml
# Service Configuration [2017-11-01r0] uploaded for service [helloworld-api.endpoints.flowing-access-184016.cloud.goog]

get-credentials:
	gcloud container clusters get-credentials endpoints-example --zone us-central1-a

#
# get-service-id - gets the service configuration ID. The output looks like:
#
# CONFIG_ID     SERVICE_NAME
# 2017-11-01r0  helloworld-api.endpoints.flowing-access-184016.cloud.goog
#
# Use these values for the -s and -v arguments respectively in container-engine.yaml
#
get-service-id:
	gcloud endpoints configs list --service=helloworld-api.endpoints.${PROJECT_NAME}.cloud.goog

# The value of SERVICE_CONFIG_ID changes each time `make deploy` is run.
# The following value is hard-coded for example purposes only.
container-engine.yaml:
	SERVICE_CONFIG_ID=2017-11-06r0 sed -e 's/#PROJECT_NAME#/${PROJECT_NAME}/g;s/#SERVICE_CONFIG_ID#/${SERVICE_CONFIG_ID}/g' container-engine.in.yaml >container-engine.yaml

create-service: container-engine.yaml
	kubectl create -f container-engine.yaml

update-service: container-engine.yaml
	kubectl apply -f container-engine.yaml

# To edit a service, use kubectl edit svc/helloworld

# Use the external IP in the hello command below
get-service-ip:
	kubectl get service

echo:
	curl -d '{"message":"hello world"}' -H "content-type:application/json" "http://35.202.48.61:80/echo?key=${ENDPOINTS_KEY}"

hello:
	curl http://35.202.127.87/hello?key=${ENDPOINTS_KEY}
