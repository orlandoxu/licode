FROM ubuntu:16.04

# 主要解决问题
# 1. apt-get 下载太慢
# 2. npm换成淘宝源
# 3. github的代码提前下载下来
# 4. pip3使用清华的mirror：
# 主要是因为：https://files.pythonhosted.org的时候，很可能会报错
# 阿里云 http://mirrors.aliyun.com/pypi/simple/
# 中国科技大学 https://pypi.mirrors.ustc.edu.cn/simple/
# 豆瓣 http://pypi.douban.com/simple
# Python官方 https://pypi.python.org/simple/
# v2ex http://pypi.v2ex.com/simple/
# 中国科学院 http://pypi.mirrors.opencas.cn/simple/
# 清华大学 https://pypi.tuna.tsinghua.edu.cn/simple/
#
#
#
#

MAINTAINER Lynckia

WORKDIR /opt

# 更新apt-get的源
# Download latest version of the code and install dependencies
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt-get clean && \
    apt-get update && apt-get install -y git wget curl

COPY .nvmrc package.json /opt/licode/
COPY ubuntu16lib /opt/licode/ubuntu16lib

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
