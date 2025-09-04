#!/usr/bin/env bash
LAB_NETWORK="lab"
HOST_NETWORK="host"

PROM_NAME="prometheus"
PROM_VERSION="v3.2.1"
PROM_PORT="9090:9090"
PROM_VOLUME="./prometheus/:/etc/prometheus/"
PROM_IMAGE="docker.io/prom/prometheus"

GRAFANA_NAME="grafana"
GRAFANA_VERSION="11.6.0"
GRAFANA_PORT="3000:3000"
GRAFANA_IMAGE="docker.io/grafana/grafana"

NODE_EXPORTER_NAME="node-exporter"
NODE_EXPORTER_VERSION="v1.9.1"
NODE_EXPORTER_VOLUME="/:/host:ro,rslave"
NODE_EXPORTER_IMAGE="docker.io/prom/node-exporter"

show_container_id() { 
	echo "$1 is already running with id $(docker ps -aq -f name=$1)"
}

if ! docker network inspect $LAB_NETWORK > /dev/null ; then 
	echo "Creating network $LAB_NETWORK"
	docker network create --driver bridge $LAB_NETWORK
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
	show_container_id $PROM_NAME
} || {
	echo "Creating $PROM_NAME container" 
	docker run -d -p $PROM_PORT --name $PROM_NAME -h $PROM_NAME --net $LAB_NETWORK -v $PROM_VOLUME  $PROM_IMAGE:$PROM_VERSION
}

docker ps -a -f name=$GRAFANA_NAME | grep -q $GRAFANA_NAME && { 
	show_container_id $GRAFANA_NAME
} || {
	echo "Creating $GRAFANA_NAME container"
	docker run -d -p $GRAFANA_PORT --name $GRAFANA_NAME -h $GRAFANA_NAME --net $LAB_NETWORK $GRAFANA_IMAGE:$GRAFANA_VERSION
}

docker ps -a -f name=$NODE_EXPORTER_NAME | grep -q $NODE_EXPORTER_NAME && { 
	show_container_id $NODE_EXPORTER_NAME
} || {
	echo "Creating $NODE_EXPORTER_NAME container" 
	docker run -d --name $NODE_EXPORTER_NAME --net $HOST_NETWORK --pid $HOST_NETWORK -v $NODE_EXPORTER_VOLUME $NODE_EXPORTER_IMAGE:$NODE_EXPORTER_VERSION --path.rootfs=/host
}
