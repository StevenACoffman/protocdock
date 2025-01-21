# Use debian stable-slim as the base image
FROM debian:stable-slim

# Avoid prompts from apt during build
ARG DEBIAN_FRONTEND=noninteractive

# Define default versions for tools needed to install Golang, Protoc, Plugins and the PATH
# https://packages.debian.org/stable/curl
# renovate: release=bookworm depName=curl
ARG CURL_VERSION="7.88.*"
# https://packages.debian.org/bookworm/git
# renovate: release=bookworm depName=git
ARG GIT_VERSION="1:2.39.*"
# https://packages.debian.org/bookworm/make
# renovate: release=bookworm depName=make
ARG MAKE_VERSION="4.3-*"
# https://packages.debian.org/bookworm/upzip
# renovate: release=bookworm depName=unzip
ARG UNZIP_VERSION="6.0-28"
# https://packages.debian.org/bookworm/ca-certificates
# renovate: release=bookworm depName=ca-certificates
ARG CA_CERTIFICATES_VERSION="20230311"
# https://packages.debian.org/bookworm/gnupg
# renovate: release=bookworm depName=gnupg
ARG GNUPG_VERSION="2.2.40-*"
# https://deb.nodesource.com/
# renovate: datasource=node-version depName=node packageName=node
ARG NODE_MAJOR=20.x
# https://github.com/golang/go/tags
# renovate: datasource=golang-version depName=go packageName=go
ARG GO_VERSION=1.23.5

# Defined default version for Protoc and Plugins
# https://github.com/protocolbuffers/protobuf
# renovate: datasource=github-releases depName=protoc packageName=protocolbuffers/protobuf/releases
ARG PROTOC_VERSION=29.3
# https://pkg.go.dev/google.golang.org/protobuf/cmd/protoc-gen-go?tab=versions
# renovate: datasource=go depName=protoc-gen-go packageName=google.golang.org/protobuf/cmd/protoc-gen-go
ARG PROTOC_GEN_GO_VERSION=1.36.3
# https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc?tab=versions
# renovate: datasource=go depName=protoc-gen-go-grpc packageName=google.golang.org/grpc/cmd/protoc-gen-go-grpc
ARG PROTOC_GEN_GO_GRPC_VERSION=1.5.1
# https://github.com/protocolbuffers/protobuf-javascript/releases
# renovate: datasource=github-releases depName=protobuf-javascript packageName=protocolbuffers/protobuf-javascript
ARG PROTOBUF_JAVASCRIPT_VERSION=3.21.4      # https://github.com/protocolbuffers/protobuf-javascript/releases
# https://github.com/grpc/grpc-web/releases
# renovate: datasource=github-releases depName=grpc-web packageName=grpc/grpc-web
ARG GRPC_WEB_VERSION=1.5.0
# https://github.com/pseudomuto/protoc-gen-doc/releases
# renovate: datasource=github-releases depName=grpc-web packageName=pseudomuto/protoc-gen-doc
ARG PROTOC_GEN_DOC_VERSION=1.5.1

# Set environment variables for Golang, Protoc, Plugins and the PATH
ENV INSTALL_DIR=/usr/local
ENV GOPATH=$INSTALL_DIR
ENV GOROOT=$INSTALL_DIR/go
ENV GO111MODULE=on 
ENV PATH=$PATH:$INSTALL_DIR:$GOROOT/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p /app && \
    mkdir -p $INSTALL_DIR/bin && \
    mkdir -p /etc/apt/keyrings/

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl=${CURL_VERSION} git=${GIT_VERSION} make=${MAKE_VERSION} unzip=${UNZIP_VERSION}

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates=${CA_CERTIFICATES_VERSION} gnupg=${GNUPG_VERSION} && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

RUN rm -rf /var/lib/apt/lists/*

# Install Golang
RUN curl -O https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Install Protocol Buffers Compiler
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d $INSTALL_DIR && \
    rm protoc-${PROTOC_VERSION}-linux-x86_64.zip

# Install ProtoC-Gen-Go plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION} && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION}

# Install GRPC-Web
RUN curl -LO https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    chmod +x protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    mv protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 $INSTALL_DIR/bin/protoc-gen-grpc-web

# Install Protobuf for JavaScript
RUN curl -LO https://github.com/protocolbuffers/protobuf-javascript/releases/download/v${PROTOBUF_JAVASCRIPT_VERSION}/protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz -C $INSTALL_DIR && \
    rm protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz

# Install Protoc-Gen-Doc
RUN curl -LO https://github.com/pseudomuto/protoc-gen-doc/releases/download/v${PROTOC_GEN_DOC_VERSION}/protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz && \
    tar -xzf protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz -C $INSTALL_DIR/bin && \
    chmod +x $INSTALL_DIR/bin/protoc-gen-doc && \
    rm protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz

# # Define a basic healthcheck (Example: For a web server, replace with actual server check command)
HEALTHCHECK --interval=10s --timeout=10s --start-period=5s CMD [ "protoc", "--version" ]

#checkov:skip=CKV_DOCKER_3:USER is not supported with github actions

# Set the working directory
WORKDIR /app

# Define the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
