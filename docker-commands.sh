#!/usr/bin/env bash
LAB_NETWORK="lab"
PROM_NAME="prometheus"
PROM_VERSION="v3.2.1"

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
	docker run -d -p 9090:9090 --name $PROM_NAME -h $PROM_NAME --net $LAB_NETWORK -v ./prometheus/:/etc/prometheus/ prom/prometheus:$PROM_VERSION
}
