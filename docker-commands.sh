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

run_container() {
	local name=$1
	local network=$2
	local image_tag=$3
	local extra_args=$4
	local image_args=$5

	if docker ps -a --format '{{.Names}}' | grep -q "^${name}$" ; then 
		echo "Container $name is already running with id $(docker ps -aq -f name=$1)"
	else 
		echo "Creating container: ${name}"
		docker run -d --name "${name}" -h "${name}" --net "${network}" ${extra_args} "${image_tag}" ${image_args}
		echo "Container ${name} created and running successfully"
	fi
}

if ! docker network inspect $LAB_NETWORK > /dev/null; then 
	echo "Creating network $LAB_NETWORK"
	docker network create --driver bridge $LAB_NETWORK
fi

if [ ! -d LFS241 ]; then
	git clone --depth=1 https://github.com/lftraining/LFS241.git
fi

if  ! docker images --format '{{.Repository}}' | grep -q "prometheus-demo-service"; then 
	echo "Building prometheus-demo-service" 
	docker build -t prometheus-demo-service LFS241/demo-service-source/.
else 
	echo "Docker image exists, running demo service containers" 
	for i in {1..3}; do
		run_container d${i} $LAB_NETWORK prometheus-demo-service 
	done;
fi

run_container "${PROM_NAME}" "${LAB_NETWORK}" "${PROM_IMAGE}:${PROM_VERSION}" "-v ${PROM_VOLUME} -p ${PROM_PORT}"
run_container "${GRAFANA_NAME}" "${LAB_NETWORK}" "${GRAFANA_IMAGE}:${GRAFANA_VERSION}" "-p ${GRAFANA_PORT}" 
run_container "${NODE_EXPORTER_NAME}" "${HOST_NETWORK}" "${NODE_EXPORTER_IMAGE}:${NODE_EXPORTER_VERSION}" "--pid ${HOST_NETWORK} -v ${NODE_EXPORTER_VOLUME}" --path.rootfs=/host
