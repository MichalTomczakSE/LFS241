#!/usr/bin/env bash
LAB_NETWORK="lab"

PROM_NAME="prometheus"
PROM_VERSION="v3.2.1"
PROM_PORT="9090:9090"

GRAFANA_NAME="grafana"
GRAFANA_VERSION="11.6.0"
GRAFANA_PORT="3000:3000"

NODE_EXPORTER_NAME="node-exporter"
NODE_EXPORTER_VERSION="v1.9.1"

if ! docker network inspect $LAB_NETWORK > /dev/null ; then 
	echo "Creating network lab"
	docker network create --driver bridge lab
fi

if [ ! -d LFS241 ]; then
	git clone --depth=1 https://github.com/lftraining/LFS241.git
fi

docker images | grep -q prometheus-demo-service && {
	echo "Image prometehus-demo-service built. Containers are running"
} || { 
	echo "Building prometheus-demo-service" 
	docker build -t prometheus-demo-service LFS241/demo-service-source/.

	for i in {1..3}; do
		echo "Creating d${i} prometheus-demo-service container"
		docker run -d --name d${i} -h d${i} --net ${LAB_NETWORK} prometheus-demo-service
	done;
}

docker ps -a -f name=$PROM_NAME | grep -q $PROM_NAME && {
	echo "$PROM_NAME is already running with id $(docker ps -aq -f name=$PROM_NAME)"
} || {
	echo "Creating $PROM_NAME container" 
	docker run -d -p $PROM_PORT --name $PROM_NAME -h $PROM_NAME --net $LAB_NETWORK -v ./prometheus/:/etc/prometheus/ prom/prometheus:$PROM_VERSION
}

docker ps -a -f name=$GRAFANA_NAME | grep -q $GRAFANA_NAME && { 
	echo "$GRAFANA_NAME is already running with id $(docker ps -aq -f name=$GRAFANA_NAME)"
} || {
	echo "Creating $GRAFANA_NAME container"
	docker run -d -p $GRAFANA_PORT --name $GRAFANA_NAME -h $GRAFANA_NAME --net $LAB_NETWORK grafana/grafana:$GRAFANA_VERSION
}

docker ps -a -f name=$DOCKER_EXPORTER_NAME | grep -q $NODE_EXPORTER_NAME && { 
	echo "$NODE_EXPORTER_NAME is already running with id $(docker ps -aq -f name=$NODE_EXPORTER_NAME)"
} || {
	echo "Creating $NODE_EXPORTER_NAME container" 
	docker run -d --name $NODE_EXPORTER_NAME --net host --pid host -v /:/host:ro,rslave prom/node-exporter:$NODE_EXPORTER_VERSION --path.rootfs=/host
}
