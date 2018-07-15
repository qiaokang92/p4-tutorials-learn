#!/bin/bash

# Print script commands.
set -x
# Exit on errors.
set -e

#--------------------
# System information
#--------------------

# Ubuntu 18.04 64bit, memory 4GB, 4 CPU cores, Disk 50 GB.

#----------------------------------
# install dependencies
#----------------------------------

sudo apt update
sudo apt upgrade
# reboot to apply upgrade before going ahead
sudo apt install -y git python-pip                       \
   g++ git automake libgc-dev bison                      \
   flex libfl-dev libgmp-dev libboost-dev                \
   libboost-iostreams-dev pkg-config python python-scapy \
   python-ipaddr tcpdump cmake                           \
   autoconf libtool curl make unzip                      \
   libssl-dev libjudy-dev libboost-all-dev libpcap-dev   \
   libreadline-dev doxygen graphviz mininet
   #texlive-full                         \

# if pip breaks, force reinstall:
#   curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#   python2.7 get-pip.py --force-reinstall
sudo pip2.7 install --upgrade pip
sudo pip2.7 install scapy thrift networkx
sudo pip2.7 install psutil

# all installation will happen in ~/p4-workspace directory
cd ~
mkdir -p p4-workspace

#-------------------------------------------------
# install protobuf
# we will install the lastest release version 3.6.0
# reference: https://github.com/google/protobuf
#-------------------------------------------------

# option 1: download and install pre-built protobuf compiler (protoc)
wget https://github.com/google/protobuf/releases/download/v3.6.0/protoc-3.6.0-linux-x86_64.zip
unzip protoc-3.6.0-linux-x86_64.zip
cd protoc
# now you can find a `protoc` executable program in `bin` folder
# you may want to add this path to PATH env variable
export PATH="$PATH:`~/p4-workspace`/protoc/bin"
# now you're able to use `protoc` command.

# option 2: build protoc from src (preferred)
wget https://github.com/google/protobuf/releases/download/v3.6.0/protobuf-python-3.6.0.tar.gz
tar zxvf protobuf-python-3.6.0.tar.gz
cd protobuf-3.6.0
./autogen.sh
./configure
make -j4
make -j4 check
sudo make install
sudo ldconfig

# option 3: install from software repo
sudo apt install -y protobuf protobuf-compiler

# build and install protobuf python runtime from src
# make sure the versions of protoc and python runtime are the same! here is 3.6.0
# reference: https://github.com/google/protobuf/tree/master/python
cd python
python setup.py build
python setup.py test
python setup.py install

# now you may want to try some protobuf samples, which can be
# found at https://developers.google.com/protocol-buffers/docs/pythontutorial

#---------------------------
# p4c installation
#----------------------------

cd ~/p4-workspace
git clone --recursive https://github.com/p4lang/p4c.git p4c
cd p4c
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG
# can be changed based on needs: options:
# cmake .. [-DCMAKE_BUILD_TYPE=RELEASE|DEBUG]
#          [-DCMAKE_INSTALL_PREFIX=<path>]
#          [-DENABLE_DOCS=ON (default off)]
#          [-DENABLE_P4RUNTIME_TO_PD=OFF (default on)]
make -j4
sudo make -j4 check
sudo make install

#---------------------------------
# behavioral-model installation
# reference: https://github.com/p4lang/behavioral-model/tree/master/targets/simple_switch_grpc
#---------------------------------

# let's rock with the newset stable version 1.11.0
git clone https://github.com/p4lang/behavioral-model.git
git checkout 1.11.0

# install gRPC
git clone https://github.com/grpc/grpc.git
cd grpc
# let's try v1.9.1
git checkout v1.9.1
# git update needs to access google
git submodule update --init --recursive
export LDFLAGS="-Wl,-s"
make -j4
sudo make install
sudo ldconfig
unset LDFLAGS

# Install gRPC Python Package
sudo pip install grpcio

# BMv2 deps (needed by PI)
cd behavioral-model
mkdir tmp
cd tmp
# From bmv2's install_deps.sh, we can skip apt-get install.
# Nanomsg is required by p4runtime, p4runtime is needed by BMv2...
# You can download and install thrift-0.11.0 from https://thrift.apache.org/download
bash ../travis/install-thrift.sh      # edit this file to install thrift-0.11.0
sudo ldconfig
bash ../travis/install-nanomsg.sh
sudo ldconfig
bash ../travis/install-nnpy.sh
sudo ldconfig
cd ..
rm -rf tmp

# PI/P4Runtime
git clone https://github.com/p4lang/PI.git
cd PI
# to run tutorials, an older commit is suggested
git checkout 219b3d67299ec09b4
git submodule update --init --recursive
./autogen.sh
# needs grpc package here
./configure --with-proto
# ./configure --with-proto --without-internal-rpc --without-cli --without-bmv2
make -j4
sudo make install
sudo ldconfig

# install behaviour model
./autogen.sh
./configure --with-pi
# Debug logging is enabled by default.
# If you want to disable it for performance reasons,
# you can type ```$./configure --disable-logging-macros``` instead.
# In 'debug mode', you probably want to disable compiler optimization
# and enable symbols in the binary: ```$./configure 'CXXFLAGS=-O0 -g'```
make -j4
sudo make -j4 check
# all test cases passed with 1.11.0
sudo make install
sudo ldconfig

# Simple_switch_grpc target
cd targets/simple_switch_grpc
./autogen.sh
./configure
make -j4
sudo make check
sudo make install
sudo ldconfig

#------------------------
# p4c-bm installation
#------------------------
cd ~/P4-workspace/
git clone https://github.com/p4lang/p4c-bm.git p4c-bmv2
cd ./p4c-bmv2/
sudo pip install -r requirements.txt
sudo pip install -r requirements_v1_1.txt
# if you are interested in compiling P4 v1.1 programs
sudo python setup.py install

#-------------------------
# tutorial installation
#-------------------------

# suggests rolling back to pre-p4d2-2018-spring
cd ~/P4-workspace/
git clone https://github.com/p4lang/tutorials.git p4_tutorial
git tag
git checkout pre-p4d2-2018-spring
cd tutorials/P4D2_2018_East/exercises
cd basic
make run
