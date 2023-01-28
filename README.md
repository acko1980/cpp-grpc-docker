# Using Docker to build and deploy a C++ gRPC service

This sample demonstrates how to create a basic gRPC service in C++ and build it it using GCC and CMake in a Docker container.
The implemented gRPC service performs elementary arithmetic.

This package is derived from both the most up to date gRPC cpp quick start guide (https://grpc.io/docs/languages/cpp/quickstart/) and an older version of the gRPC service in a Docker container (https://github.com/npclaudiu/grpc-cpp-docker).

# Instructions for Use

## 1. Building the Docker Image

```sh
git clone https://github.com/acko1980/cpp-grpc-docker.git
cd cpp-grpc-docker
docker build --platform linux/amd64 . -t cpp-grpc-calculator:0.1.0
```

The first build will take some time, as it also clones, builds and installs *protobuf*
and *grpc*. You should end up with a Docker image tagged *cpp-grpc-calculator*, based on Ubuntu and
containing the release build of the calculator service and all of its dependencies,
all under `/calculator`. There are also several intermediary build images, where the project
is actually built. Please see the `Dockerfile` and the documentation for
[Docker multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
for more.

## 2. Running the Calculation server and client

The server can be run in an interactive docker window through the following commands.

```sh
docker run --rm -it --platform linux/amd64 docker.io/library/cpp-grpc-calculator:0.1.0
./server &
Calculator server listening on 0.0.0.0:50051
```

The server can be started without connecting to the docker container:

```sh
docker run --rm -ti --platform linux/amd64 --entrypoint /calculator/server docker.io/library/cpp-grpc-calculator:0.1.0
Calculator server listening on 0.0.0.0:50051
```

Then find the IP address of the server container:

```sh
docker ps
CONTAINER ID   IMAGE                    COMMAND                CREATED         STATUS         PORTS       NAMES
9cd811e29618   cpp-build-server:0.1.0   "/calculator/server"   6 seconds ago   Up 6 seconds   50051/tcp   tender_galois

docker inspect 9cd811e29618 | grep -i IPAddress
"SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.2",
                    "IPAddress": "172.17.0.2"
```

 The client can then connect from a second instance of the docker image:

 ```sh
 docker run --rm -ti --platform linux/amd64 --entrypoint /calculator/client docker.io/library/cpp-grpc-calculator:0.1.0 --target=172.17.0.2:50051
 Calculator response received: 10
 ```
