FROM    ubuntu:22.04 AS base

## Install libraries by package
ENV     DEBIAN_FRONTEND=noninteractive
RUN     apt-get update && apt-get install -y tzdata sudo curl git && adduser -D -h /home/container container

FROM    base AS build

WORKDIR /tmp

ARG     OME_VERSION=master
ARG 	STRIP=TRUE

ENV     PREFIX=/home/container/ovenmediaengine
ENV     TEMP_DIR=/tmp/ome

## Download OvenMediaEngine
RUN \
        mkdir -p ${TEMP_DIR} && \
        cd ${TEMP_DIR} && \
        git clone --branch ${OME_VERSION} --single-branch --depth 1 https://github.com/SandwichFox/OME-Pterodactyl .

## Install dependencies
RUN \
        ${TEMP_DIR}/misc/prerequisites.sh 

## Build OvenMediaEngine
RUN \
        cd ${TEMP_DIR}/src && \
        make release -j$(nproc)

RUN \
        if [ "$STRIP" = "TRUE" ] ; then strip ${TEMP_DIR}/src/bin/RELEASE/OvenMediaEngine ; fi

## Make running environment
RUN \
        cd ${TEMP_DIR}/src && \
        mkdir -p ${PREFIX}/bin/origin_conf && \
        mkdir -p ${PREFIX}/bin/edge_conf && \
        cp ./bin/RELEASE/OvenMediaEngine ${PREFIX}/bin/ && \
        cp ../misc/conf_examples/Origin.xml ${PREFIX}/bin/origin_conf/Server.xml && \
        cp ../misc/conf_examples/Logger.xml ${PREFIX}/bin/origin_conf/Logger.xml && \
        cp ../misc/conf_examples/Edge.xml ${PREFIX}/bin/edge_conf/Server.xml && \
        cp ../misc/conf_examples/Logger.xml ${PREFIX}/bin/edge_conf/Logger.xml && \
        cp ../misc/install_nvidia_driver.sh ${PREFIX}/bin/install_nvidia_driver.sh && \
        rm -rf ${TEMP_DIR}

FROM	base AS release

WORKDIR         /home/container
COPY            --from=build /home/container/ovenmediaengine /home/container/ovenmediaengine

# Run the entrypoint.sh
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]