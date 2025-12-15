#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export FS=$THISDIR/..
if [[ "x$TE_LIBS" == "x" ]]; then
    export HD=/opt/mazoea
    export TE_LIBS=$HD/installation
fi
export TE_LIBS_LOGS=$TE_LIBS/__logs
mkdir -p $TE_LIBS/ || true

if [[ "x$BUILDER" == "x" ]]; then
    export BUILDER="XXX-$(hostname -s)-$HOSTID"
fi
if [[ "x$VERSION" == "x" ]]; then
    export BUILDINFO=$BUILDER
else
    export BUILDINFO=$BUILDER-$VERSION
fi

if [[ "x$CI" == "xshippable" ]]; then
    echo "Using shippable testresults/codecoverage directories"
    export SDTR=$FS/shippable/testresults
    mkdir -p $SDTR
    export SDCR=$FS/shippable/codecoverage
    mkdir -p $SDCR
fi

# must be sourced for this
if [[ "x$SETVARSONLY" == "xtrue" ]]; then
    return
fi

locale -a
update-locale LANG=$LANG || echo "problem setting locale"

if [[ -f $FS/apt-requirements.txt ]]; then
    echo "apt-ing"
    sudo apt-get -qq update
    echo "apt-ing $FS/apt-requirements.txt"
    xargs apt-get -q install -y < $FS/apt-requirements.txt
fi

if [[ "x$GIT_CONFIGURE" == "xtrue" ]]; then
    echo "Updating git"
    export GITDEPTH="--depth 3"
    git config --global user.name "jm@mazoea"
    git config --global user.email "jm@$BUILDER"
    git config --global core.filemode false
fi

sudo updatedb
echo "whoami `whoami`"
echo "pwd `pwd`"
echo "hostname `hostname`"
cat /proc/cpuinfo || echo "cpuinfo problem"
gcc --version || echo "gcc not present"
g++ --version || echo "g++ not present"
# sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
# sudo apt-get update &> /dev/null

# #GGMAJOR=`g++ -dumpversion | cut -f1 -d.`
# if [[ "x$GCCVERSION" != "x" ]]; then
#     VERSION=$GCCVERSION
# else
#     VERSION=4.8
# fi
# echo "installing g++$VERSION"
# sudo apt-get -q install -y gcc-$VERSION g++-$VERSION
# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$VERSION 90 --slave /usr/bin/g++ g++ /usr/bin/g++-$VERSION
# gcc --version || echo "gcc not present"
# g++ --version || echo "g++ not present"
# echo "gcc flags default detection"
# gcc -Q --help=target
# echo "gcc flags native detection"
# gcc -Q --help=target -march=native 

# echo "installing cmake3"
# sudo add-apt-repository ppa:george-edison55/cmake-3.x -y
# sudo apt-get update &> /dev/null
# sudo apt-get -q install -y cmake
# sudo add-apt-repository --remove ppa:george-edison55/cmake-3.x -y
# cmake --version || echo "cmake not present"
