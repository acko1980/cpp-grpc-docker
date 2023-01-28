# Ubuntu dependencies - currently at Ubuntu 22.04 - Jammy Jellyfish

FROM ubuntu:jammy AS base

LABEL MAINTAINER="Tom Atkinson <acko@icloud.com>"

# Prevent interactive messages while installing libraries
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y build-essential git autoconf libtool pkg-config wget openssl

# Install CMake 3.25.1
ARG CMAKE_VER=3.25
ARG CMAKE_BUILD=1
RUN cd /usr/local/ && \
    wget --no-check-certificate https://cmake.org/files/v${CMAKE_VER}/cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64.tar.gz && \
    tar -xzf ./cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64.tar.gz && \
    rm -r ./cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64.tar.gz && \
    ln -s /usr/local/cmake-${CMAKE_VER}.${CMAKE_BUILD}-linux-x86_64/bin/cmake /usr/bin/cmake


# gRPC compile
FROM base as grpc

RUN mkdir -p grpc

COPY grpc/install_grpc.sh .

RUN chmod u+x install_grpc.sh

RUN bash -c "./install_grpc.sh"

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
