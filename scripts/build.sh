#!/bin/bash
set -e -o pipefail

LOCAL_THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Working in `pwd`"

source $LOCAL_THISDIR/functions.sh

LOCAL_THISSCRIPT="setup.prereq.sh"
entered "$LOCAL_THISSCRIPT" 
LOCAL_start=`date +%s` 

pushd ..
LOCALCDN=$LOCAL_THISDIR/..
export MAKE_AUTOCONF=true
export MAKE_AUTOMAKE=true

#=====================================================
# autoconf
#

cd $TE_LIBS
VER=2.69
INSTALLED_VERSION=`autoconf --version | grep autoconf | cut -d' ' -f 4 || true`
if [[ "x$MAKE_AUTOCONF" == "xtrue" && "x$INSTALLED_VERSION" != "x$VER" ]]; then
    PACKAGE=autoconf-$VER
    #URL=http://ftp.gnu.org/gnu/autoconf/$PACKAGE.tar.gz
    URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
    autoconf --version | grep autoconf || true
    install_dep_with_autoconf $PACKAGE $URL " --prefix=/usr" 
    sudo cp ./bin/autoconf /usr/bin/autoconf
    autoconf --version | grep autoconf
else
    echo "assumed autoconf is present"
fi
minisep "autoconf"
autoconf --version
minisep

cd $TE_LIBS
VER=1.15
INSTALLED_VERSION=`automake --version | grep automake | cut -d' ' -f 4 || true`
if [[ "x$MAKE_AUTOMAKE" == "xtrue" && "x$INSTALLED_VERSION" != "x$VER" ]]; then
    PACKAGE=automake-$VER
    #URL=http://ftp.gnu.org/gnu/automake/$PACKAGE.tar.gz
    URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
    automake --version || true
    cd $TE_LIBS
    download_and_unpack_tar_gz $PACKAGE $URL
    cd $PACKAGE
    chmod +x ./configure
    # for fuck's sake why, tell me why!
    ./configure && make bin/aclocal bin/automake && make lib/Automake/Config.pm
    sudo make install
    #install_raw $PACKAGE " --prefix=/usr"
    automake --version
else
    echo "assumed automake is present"
fi
minisep "automake"
automake --version || echo "automake not present"
minisep

if [[ "x$CPU_NATIVE" == "xtrue" ]]; then
    echo "Using NATIVE compilation"
    export MAZCCFLAGS="-O3 -DNDEBUG -march=native -fPIC"
fi

#=====================================================
# zlib - before everything
#
cd $TE_LIBS

VER=1.2.11
PACKAGE=zlib-$VER
#URL="http://sourceforge.net/projects/libpng/files/zlib/$VER/$PACKAGE.tar.gz/download?use_mirror=cznic&download="
URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
LIB_SO=$TE_LIBS/lib/libz.so
LIB_A=$TE_LIBS/lib/libz.a
if [[ ! -f $LIB_A ]]; then
    time install_dep_with_autoconf $PACKAGE $URL
    check_ldd $LIB_SO
fi


#=====================================================
# libpng - should be before freetype
#
cd $TE_LIBS

VER=1.6.29
PACKAGE=libpng-$VER
#URL=http://prdownloads.sourceforge.net/libpng/$PACKAGE.tar.gz?download
URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
LIB_SO=$TE_LIBS/lib/libpng16.so
LIB_A=$TE_LIBS/lib/libpng16.a
if [[ ! -f $LIB_A ]]; then
    time install_dep_with_autoconf $PACKAGE $URL
    check_ldd $LIB_SO
fi


#=====================================================
# freetype
#
cd $TE_LIBS

VER=2.8
PACKAGE=freetype-$VER
#URL="http://download.savannah.gnu.org/releases/freetype/$PACKAGE.tar.gz"
URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
LIB_SO=$TE_LIBS/lib/libfreetype.so
LIB_A=$TE_LIBS/lib/libfreetype.a
if [[ ! -f $LIB_A ]]; then
    time LIBPNG_LIBS="-L$TE_LIBS/libs -lpng" LIBPNG_CFLAGS="-I$TE_LIBS/include" install_dep_with_autoconf $PACKAGE $URL
    check_ldd $LIB_SO
fi


#=====================================================
# libgiff
#
cd $TE_LIBS

if [[ "x$COMPILE_GIFLIB" != "xfalse" ]]; then
    echo "Using MAZOEA LEPTONICA - using GIFLIB 5.x"
    VER=5.1.4
    #URL=http://sourceforge.net/projects/giflib/files/giflib-$VER.tar.gz/download

    PACKAGE=giflib-$VER
    URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"

    LIB_SO=$TE_LIBS/lib/libgif.so
    LIB_A=$TE_LIBS/lib/libgif.a
    if [[ ! -f $LIB_A ]]; then
        cd $TE_LIBS
        download_and_unpack_tar_gz $PACKAGE $URL
        cd $PACKAGE
        autoreconf --force --install # > $TE_LIBS_LOGS/$PACKAGE.autoreconf.log 2>&1
        time install_raw $PACKAGE
        check_ldd $LIB_SO
    fi
fi

#=====================================================
# libjpeg
#
cd $TE_LIBS

VER=9b
PACKAGE_RAW=jpegsrc.v$VER
PACKAGE=jpeg-$VER
#URL=http://www.ijg.org/files/jpegsrc.v$VER.tar.gz
URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
LIB_SO=$TE_LIBS/lib/libjpeg.so
LIB_A=$TE_LIBS/lib/libjpeg.a
if [[ ! -f $LIB_A ]]; then
    download_and_unpack_generic $PACKAGE.tar.gz $PACKAGE $URL "tar xzvf"
    cd $PACKAGE
    time install_raw $PACKAGE
    check_ldd $LIB_SO
fi


#=====================================================
# libtiff
#
cd $TE_LIBS

VER=4.0.8
PACKAGE=tiff-$VER
#URL=http://download.osgeo.org/libtiff/$PACKAGE.tar.gz
URL="https://mazoea.com/cdn/$PACKAGE.tar.gz"
LIB_SO=$TE_LIBS/lib/libtiff.so
LIB_A=$TE_LIBS/lib/libtiff.a
if [[ ! -f $LIB_A ]]; then
    time install_dep_with_autoconf $PACKAGE $URL "--disable-jbig --disable-lzma"
    check_ldd $LIB_SO
fi

sep

popd

sep
LOCAL_end=`date +%s`
echo "Script $LOCAL_THISSCRIPT took $((LOCAL_end-LOCAL_start)) seconds"
sep 