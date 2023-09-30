# Ubuntu dependencies - currently at Ubuntu 22.04 - Jammy Jellyfish

FROM ubuntu:jammy AS base

LABEL MAINTAINER="Tom Atkinson <acko@icloud.com>"

ARG TARGETARCH

# Prevent interactive messages while installing libraries
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y build-essential git autoconf libtool pkg-config wget libev-dev gdb swig ninja-build libz-dev libsystemd-dev

# CMake
ARG CMAKE_VER=3.27
ARG CMAKE_BUILD=6

RUN <<EOT

    if [ "amd64" = "$TARGETARCH" ]; then
        CMAKE_FN=cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64.tar.gz
        CMAKE_DIR=/usr/local/cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64
    elif [ "arm64" = "$TARGETARCH" ]; then
        CMAKE_FN=cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-aarch64.tar.gz
        CMAKE_DIR=/usr/local/cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-aarch64
    fi

    CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}.${CMAKE_BUILD}/${CMAKE_FN}

    cd /usr/local/
    wget ${CMAKE_URL}
    tar -xzf ./${CMAKE_FN}
    rm -r ./${CMAKE_FN}
    ln -s ${CMAKE_DIR}/bin/cmake /usr/bin/cmake

EOT

# gRPC compile
FROM base as grpc

RUN git clone --recurse-submodules -b v1.58.1 --depth 1 --shallow-submodules https://github.com/grpc/grpc

SHELL ["/bin/bash", "-c"]
RUN <<EOT
    
    export MY_INSTALL_DIR=$HOME/.local
    mkdir -p ${MY_INSTALL_DIR}

    cd grpc

    mkdir -p cmake/build
    pushd cmake/build
    
    cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR ../..

    popd

EOT

SHELL ["/bin/bash", "-c"]
RUN <<EOT

    cd grpc
    pushd cmake/build

    make -j4
    make install

    popd

EOT

# calculator service and client compile
FROM base AS calculator_build

COPY --from=grpc /root/.local /root/.local

ENV MY_INSTALL_DIR=/root/.local
ENV PATH="$MY_INSTALL_DIR/bin:$PATH"

RUN mkdir -p calculator
WORKDIR /calculator
COPY calculator/ .

RUN cmake .
RUN make

FROM base AS calculator

COPY --from=grpc /root/.local /root/.local

EXPOSE 50051

WORKDIR /calculator

COPY --from=calculator_build /calculator/server .
COPY --from=calculator_build /calculator/client .
