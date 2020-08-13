#!/usr/bin/env bash

set -e

SCRIPT=`pwd`/$0
FILENAME=`basename $SCRIPT`
PATHNAME=`dirname $SCRIPT`
ROOT=$PATHNAME/..
BUILD_DIR=$ROOT/build
CURRENT_DIR=`pwd`
NVM_CHECK="$PATHNAME"/checkNvm.sh

LIB_DIR=$BUILD_DIR/libdeps
PREFIX_DIR=$LIB_DIR/build/
FAST_MAKE=''

check_sudo(){
  if [ -z `command -v sudo` ]; then
    echo 'sudo is not available, will install it.'
    apt-get update -y
    apt-get install sudo
  fi
}

parse_arguments(){
  while [ "$1" != "" ]; do
    case $1 in
      "--enable-gpl")
        ENABLE_GPL=true
        ;;
      "--cleanup")
        CLEANUP=true
        ;;
      "--fast")
        FAST_MAKE='-j4'
        ;;
    esac
    shift
  done
}

check_proxy(){
  if [ -z "$http_proxy" ]; then
    echo "No http proxy set, doing nothing"
  else
    echo "http proxy configured, configuring npm"
    npm config set proxy $http_proxy
  fi

  if [ -z "$https_proxy" ]; then
    echo "No https proxy set, doing nothing"
  else
    echo "https proxy configured, configuring npm"
    npm config set https-proxy $https_proxy
  fi
}

install_nvm_node() {
  if [ -d $LIB_DIR ]; then
    export NVM_DIR=$(readlink -f "$LIB_DIR/nvm")
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
      ls -al /opt/licode/
      ls -al /opt/licode/ubuntu16lib
      cp -r /opt/licode/ubuntu16lib/nvm "$NVM_DIR"
#      拒绝在网上下载，只用用本地的
#      git clone https://github.com/creationix/nvm.git "$NVM_DIR"
#      cd "$NVM_DIR"
#      git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
      cd "$CURRENT_DIR"
    fi
    . $NVM_CHECK
    # 官方会去这里下载
    # http://nodejs.org/dist/v12.13.0/node-v12.13.0-linux-x64.tar.gz
    # 换成淘宝试试
    NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node nvm install
  else
    mkdir -p $LIB_DIR
    install_nvm_node
  fi
}

install_apt_deps(){
  install_nvm_node
  nvm use
  # 使用淘宝的源
  npm config set registry https://registry.npm.taobao.org
  npm install
  sudo apt-get update -y
  sudo apt-get install -qq python-software-properties -y
  sudo apt-get install -qq software-properties-common -y
#  orlando modify here.
# 因为我修改了阿里源，所以这里无法添加ppa了。先注释了试试
#  sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
  sudo apt-get update -y
  sudo apt-get install -qq git make gcc-5 g++-5 python3-pip libssl-dev cmake pkg-config liblog4cxx10-dev rabbitmq-server mongodb curl autoconf libtool automake -y
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5

# orlando add mkdir here.
# 因为报错：chown: cannot access '/root/tmp/': No such file or directory
  mkdir ~/tmp
  sudo chown -R `whoami` ~/.npm ~/tmp/ || true
}

install_conan(){
#  pip3 install conan==1.21
# 会遇到下面这个问题，然后加上--trusted-host就行了
# The repository located at mirrors.aliyun.com is not a trusted or secure host
# and is being ignored. If this repository is available via HTTPS it is recommended to use HTTPS instead,
# otherwise you may silence this warning and allow it anyways with
# '--trusted-host mirrors.aliyun.com'.
 pip3 install --index http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com conan==1.21
# 再不行试试：https://pypi.douban.com/simple
}

download_openssl() {
  OPENSSL_VERSION=$1
  OPENSSL_MAJOR="${OPENSSL_VERSION%?}"
# 这儿直接用下载好的
#  echo "Downloading OpenSSL from https://www.openssl.org/source/$OPENSSL_MAJOR/openssl-$OPENSSL_VERSION.tar.gz"
#  curl -OL https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
#  tar -zxvf openssl-$OPENSSL_VERSION.tar.gz
#  DOWNLOAD_SUCCESS=$?
#  if [ "$DOWNLOAD_SUCCESS" -eq 1 ]
#  then
#    echo "Downloading OpenSSL from https://www.openssl.org/source/old/$OPENSSL_MAJOR/openssl-$OPENSSL_VERSION.tar.gz"
#    curl -OL https://www.openssl.org/source/old/$OPENSSL_MAJOR/openssl-$OPENSSL_VERSION.tar.gz
  cp /opt/licode/ubuntu16lib/openssl-$OPENSSL_VERSION.tar.gz .
  tar -zxvf openssl-$OPENSSL_VERSION.tar.gz
#  fi
}

install_openssl(){
  if [ -d $LIB_DIR ]; then
    cd $LIB_DIR
    OPENSSL_VERSION=`node -pe process.versions.openssl`
    if [ ! -f ./openssl-$OPENSSL_VERSION.tar.gz ]; then
      download_openssl $OPENSSL_VERSION
      cd openssl-$OPENSSL_VERSION
      ./config --prefix=$PREFIX_DIR --openssldir=$PREFIX_DIR -fPIC
      make $FAST_MAKE -s V=0
      make install_sw
    else
      echo "openssl already installed"
    fi
    cd $CURRENT_DIR
  else
    mkdir -p $LIB_DIR
    install_openssl
  fi
}

install_opus(){
  [ -d $LIB_DIR ] || mkdir -p $LIB_DIR
  cd $LIB_DIR
  if [ ! -f ./opus-1.1.tar.gz ]; then
    # 这里直接拷贝源代码
    # curl -L https://github.com/xiph/opus/archive/v1.1.tar.gz -o opus-1.1.tar.gz
    cp -r /opt/licode/ubuntu16lib/opus-1.1.tar.gz .
    tar -zxvf opus-1.1.tar.gz
    cd opus-1.1
    ./autogen.sh
    ./configure --prefix=$PREFIX_DIR
    make $FAST_MAKE -s V=0
    make install
  else
    echo "opus already installed"
  fi
  cd $CURRENT_DIR
}

install_mediadeps(){
  install_opus
  sudo apt-get -qq install yasm libvpx. libx264.
  if [ -d $LIB_DIR ]; then
    cd $LIB_DIR
    if [ ! -f ./v11.9.tar.gz ]; then
      # curl -O -L https://github.com/libav/libav/archive/v11.9.tar.gz
      # 这儿直接拷贝
      cp -r /opt/licode/ubuntu16lib/v11.9.tar.gz .
      tar -zxvf v11.9.tar.gz
      cd libav-11.9
      PKG_CONFIG_PATH=${PREFIX_DIR}/lib/pkgconfig ./configure --prefix=$PREFIX_DIR --enable-shared --enable-gpl --enable-libvpx --enable-libx264 --enable-libopus --disable-doc
      make $FAST_MAKE -s V=0
      make install
    else
      echo "libav already installed"
    fi
    cd $CURRENT_DIR
  else
    mkdir -p $LIB_DIR
    install_mediadeps
  fi

}

install_mediadeps_nogpl(){
  install_opus
  sudo apt-get -qq install yasm libvpx.
  if [ -d $LIB_DIR ]; then
    cd $LIB_DIR
    if [ ! -f ./v11.9.tar.gz ]; then
      # curl -O -L https://github.com/libav/libav/archive/v11.9.tar.gz
      # 这儿直接拷贝
      cp -r /opt/licode/ubuntu16lib/v11.9.tar.gz .
      tar -zxvf v11.9.tar.gz
      cd libav-11.9
      PKG_CONFIG_PATH=${PREFIX_DIR}/lib/pkgconfig ./configure --prefix=$PREFIX_DIR --enable-shared --enable-libvpx --enable-libopus --disable-doc
      make $FAST_MAKE -s V=0
      make install
    else
      echo "libav already installed"
    fi
    cd $CURRENT_DIR
  else
    mkdir -p $LIB_DIR
    install_mediadeps_nogpl
  fi
}

install_libsrtp(){
  if [ -d $LIB_DIR ]; then
    cd $LIB_DIR
    # curl -o libsrtp-2.1.0.tar.gz https://codeload.github.com/cisco/libsrtp/tar.gz/v2.1.0
    # 这儿直接拷贝
    cp -r /opt/licode/ubuntu16lib/libsrtp-2.1.0.tar.gz .
    tar -zxvf libsrtp-2.1.0.tar.gz
    cd libsrtp-2.1.0
    CFLAGS="-fPIC" ./configure --enable-openssl --prefix=$PREFIX_DIR --with-openssl-dir=$PREFIX_DIR
    make $FAST_MAKE -s V=0 && make uninstall && make install
    cd $CURRENT_DIR
  else
    mkdir -p $LIB_DIR
    install_libsrtp
  fi
}

cleanup(){
  if [ -d $LIB_DIR ]; then
    cd $LIB_DIR
    rm -r libsrtp*
    rm -r libav*
    rm -r v11*
    rm -r openssl*
    rm -r opus*
    cd $CURRENT_DIR
  fi
}

parse_arguments $*

mkdir -p $PREFIX_DIR

check_sudo
install_apt_deps
install_conan
check_proxy
install_openssl
install_libsrtp

install_opus
if [ "$ENABLE_GPL" = "true" ]; then
  install_mediadeps
else
  install_mediadeps_nogpl
fi

if [ "$CLEANUP" = "true" ]; then
  echo "Cleaning up..."
  cleanup
fi
