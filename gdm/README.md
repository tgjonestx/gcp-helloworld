1) Edit cluster.yaml to set desired zone

2) ```gcloud deployment-manager deployments create gke-cluster --config cluster.yaml```

3)
```
IMAGE=gcr.io/noodling-184719/helloworld
SERVICE_CONFIG=2017-11-06r0
gcloud deployment-manager deployments create hello --template replicatedservice.py --properties clusterType:gke-cluster-my-cluster-type,image:$IMAGE,service-config:$SERVICE_CONFIG
```


