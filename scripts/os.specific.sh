#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export FS=$THISDIR/..
if [[ "x$TE_LIBS" == "x" ]]; then
    export HD=/opt/mazoea
    export TE_LIBS=$HD/installation
    export TE_LIBS_LOGS=$TE_LIBS/__logs
fi

locale -a
update-locale LANG=$LANG || echo "problem setting locale"

sudo updatedb
echo "whoami `whoami`"
echo "pwd `pwd`"
echo "hostname `hostname`"
cat /proc/cpuinfo || echo "cpuinfo problem"
gcc --version || echo "gcc not present"
g++ --version || echo "g++ not present"
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update &> /dev/null

if [[ -f $FS/apt-requirements.txt ]]; then
    echo "apt-ing"
    sudo apt-get -qq update
    echo "apt-ing $FS/apt-requirements.txt"
    xargs apt-get -q install -y < $FS/apt-requirements.txt
fi 

#GGMAJOR=`g++ -dumpversion | cut -f1 -d.`
if [[ "x$GCCVERSION" != "x" ]]; then
    VERSION=$GCCVERSION
else
    VERSION=4.8
fi
echo "installing g++$VERSION"
sudo apt-get -q install -y gcc-$VERSION g++-$VERSION
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$VERSION 90 --slave /usr/bin/g++ g++ /usr/bin/g++-$VERSION
gcc --version || echo "gcc not present"
g++ --version || echo "g++ not present"
echo "gcc flags default detection"
gcc -Q --help=target
echo "gcc flags native detection"
gcc -Q --help=target -march=native 

echo "installing cmake3"
sudo add-apt-repository ppa:george-edison55/cmake-3.x
sudo apt-get update &> /dev/null
sudo apt-get -q install -y cmake
cmake --version || echo "cmake not present"
