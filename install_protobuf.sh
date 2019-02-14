#!/bin/sh

PROTOBUF_VERSION=3.6.1

sudo apt install libtool

mkdir -p protobuf && \
  cd protobuf && \
  wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-all-${PROTOBUF_VERSION}.zip && \
  unzip -qq protobuf-all-${PROTOBUF_VERSION}.zip && \
  cd protobuf-${PROTOBUF_VERSION} && \
  ./autogen.sh && \
  ./configure --prefix=/usr && \
  cd src && make -j4 && \
  make install
cd ..
rm -rf protobuf
