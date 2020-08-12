FROM ubuntu:16.04

# 主要解决问题
# 1. apt-get 下载太慢
# 2. npm换成淘宝源
# 3. github的代码提前下载下来

MAINTAINER Lynckia

WORKDIR /opt

# 更新apt-get的源
# Download latest version of the code and install dependencies
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt-get clean && \
    apt-get update && \
    apt-get update && apt-get install -y git wget curl

COPY .nvmrc package.json ubuntu16lib /opt/licode/

COPY scripts/installUbuntuDeps.sh scripts/checkNvm.sh scripts/libnice-014.patch0 /opt/licode/scripts/

WORKDIR /opt/licode/scripts

RUN ./installUbuntuDeps.sh --cleanup --fast

WORKDIR /opt

COPY . /opt/licode

RUN mkdir /opt/licode/.git

# Clone and install licode
WORKDIR /opt/licode/scripts

RUN ./installErizo.sh -dfeacs && \
    ./../nuve/installNuve.sh && \
    ./installBasicExample.sh

WORKDIR /opt/licode

ARG COMMIT

RUN echo $COMMIT > RELEASE
RUN date --rfc-3339='seconds' >> RELEASE
RUN cat RELEASE

WORKDIR /opt

ENTRYPOINT ["./licode/extras/docker/initDockerLicode.sh"]
