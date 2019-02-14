FROM alpine:latest as builder

ENV CXXTEST_VERSION=4.4
ENV CXXTEST_ARCHIVE=cxxtest-${CXXTEST_VERSION}.tar.gz
ENV CXXTEST_EXTRACT=cxxtest-${CXXTEST_VERSION}
ENV CXXTEST_OUT_DIR=/cxxtest

RUN apk add --update ca-certificates openssl && update-ca-certificates

RUN wget https://github.com/CxxTest/cxxtest/releases/download/${CXXTEST_VERSION}/${CXXTEST_ARCHIVE}
RUN tar xf ${CXXTEST_ARCHIVE}
RUN mkdir -p ${CXXTEST_OUT_DIR}/bin
RUN cp ${CXXTEST_EXTRACT}/bin/cxxtestgen ${CXXTEST_OUT_DIR}/bin
RUN cp -r ${CXXTEST_EXTRACT}/python ${CXXTEST_OUT_DIR}
RUN cp -r ${CXXTEST_EXTRACT}/cxxtest ${CXXTEST_OUT_DIR}


FROM alpine:latest

# ply is installed to allow cxxtestgen to be used with the FOG parser for
# test discovery.
# See http://cxxtest.com/guide.html#_test_discovery_options
RUN apk --no-cache add\
  python3 \
  python3-dev \
  g++ \
  make \
  bash \
  cmake \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && pip3 --no-cache-dir install ply==3.10

COPY --from=builder /cxxtest /cxxtest
ENV PATH="/cxxtest/bin:${PATH}" CXXTEST="/cxxtest"

# install opencv
RUN echo -e '@edgunity http://nl.alpinelinux.org/alpine/edge/community\n\
@edge http://nl.alpinelinux.org/alpine/edge/main\n\
@testing http://nl.alpinelinux.org/alpine/edge/testing\n\
@community http://dl-cdn.alpinelinux.org/alpine/edge/community'\
  >> /etc/apk/repositories

RUN apk add --update --no-cache \
  # --virtual .build-deps \
      build-base \
      openblas-dev \
      unzip \
      #Intel® TBB, a widely used C++ template library for task parallelism'
      libtbb@testing  \
      libtbb-dev@testing   \
      # Wrapper for libjpeg-turbo
      libjpeg  \
      # accelerated baseline JPEG compression and decompression library
      libjpeg-turbo-dev \
      # Portable Network Graphics library
      libpng-dev \
      # A software-based implementation of the codec specified in the emerging JPEG-2000 Part-1 standard (development files)
      jasper-dev \
      # Provides support for the Tag Image File Format or TIFF (development files)
      tiff-dev \
      # Libraries for working with WebP images (development files)
      libwebp-dev \
      # A C language family front-end for LLVM (development files)
      clang-dev \
      linux-headers && \
  pip3 install numpy

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

ENV OPENCV_VERSION=3.4.3

RUN mkdir opencv && cd opencv && \
  wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
  unzip ${OPENCV_VERSION}.zip && \
  rm -rf ${OPENCV_VERSION}.zip && \
  cd opencv-${OPENCV_VERSION}

RUN mkdir -p opencv/opencv-${OPENCV_VERSION}/build && \
  cd opencv/opencv-${OPENCV_VERSION}/build && \
  cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D WITH_FFMPEG=NO \
  -D WITH_IPP=NO \
  -D WITH_OPENEXR=NO \
  -D WITH_TBB=YES \
  -D BUILD_EXAMPLES=NO \
  -D BUILD_ANDROID_EXAMPLES=NO \
  -D INSTALL_PYTHON_EXAMPLES=NO \
  -D BUILD_DOCS=NO \
  -D BUILD_opencv_python2=NO \
  -D BUILD_opencv_python3=ON \
  -D PYTHON3_EXECUTABLE=/usr/local/bin/python \
  -D PYTHON3_INCLUDE_DIR=/usr/local/include/python3.6m/ \
  -D PYTHON3_LIBRARY=/usr/local/lib/libpython3.so \
  -D PYTHON_LIBRARY=/usr/local/lib/libpython3.so \
  -D PYTHON3_PACKAGES_PATH=/usr/local/lib/python3.6/site-packages/ \
  -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.6/site-packages/numpy/core/include/ \
  .. && \
  make -j7 && \
  make install

RUN rm -rf opencv
ENV PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/local/lib64/pkgconfig"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/lib64"

#install packages for protobuf
RUN apk add --no-cache --update autoconf automake libtool
ADD install_protobuf.sh /tmp/install_protobuf.sh
RUN set -ex && /tmp/install_protobuf.sh
