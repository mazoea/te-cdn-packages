#!/bin/bash
#
# part of Mazoea TE QA
#
# use env PATH=$PATH for path propagation to sudo

#=====================================================
# paths
#=====================================================

if [[ -n "$(command -v apt)" ]]; then
    APT_AVAIL=true
else
    APT_AVAIL=false
fi

if [[ -n "$(command -v yum)" ]]; then
    YUM_AVAIL=true
else
    YUM_AVAIL=false
fi

TRIMMER="tail -100" 

# if [[ "x$SLACK" == "x" ]]; then
#     echo '$SLACK' not set - will be ignored!
# fi

# echo "Using $TE_LIBS_LOGS as logging directory"
if [[ "x$TE_LIBS" != "x" ]]; then
    mkdir -p $TE_LIBS || true
    mkdir -p $TE_LIBS_LOGS || true
    mkdir -p $TE_LIBS/lib || true
    mkdir -p $TE_LIBS/include || true
fi

#=====================================================
# functions
#=====================================================

sep() {
    echo "------------------------"
}

minisep() {
    if [[ "x$1" != "x" ]]; then
        echo
        echo "  ==================== $1 ======================="
    else
        echo "  ====                                       ===="
    fi
}

microsep() {
    if [[ "x$1" != "x" ]]; then
        echo
        echo "  --- $1"
    else
        echo "  ---"
    fi
}

entered() {
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo "XX                                 $1                                   XX"
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

info() {
    if [[ "x$MAZNOTIFY" == "xtrue" && "x$SLACK" != "x" ]]; then
        curl -s -X POST --data-urlencode "payload={\"pretext\": \"$2\", \"text\": \"$1\", \"username\": \"$BUILDINFO-$REPO_NAME\", \"color\": \"#36a64f\", \"icon_emoji\": \":checkered_flag:\"}" "$SLACK" > /dev/null
    fi
}

warn() {
    if [[ "x$MAZNOTIFY" == "xtrue" && "x$SLACK" != "x" ]]; then
        curl -s -X POST --data-urlencode "payload={\"pretext\": \"$2\", \"text\": \"$1\", \"username\": \"$BUILDINFO-$REPO_NAME\", \"color\": \"#ff0000\", \"icon_emoji\": \":point_up:\"}" "$SLACK" > /dev/null
    fi
}

result() {
    if [[ "x$MAZNOTIFYRESULT" == "xtrue" && "x$SLACK" != "x" ]]; then
        curl -s -X POST --data-urlencode "payload={\"pretext\": \"$2\", \"text\": \"$1\", \"username\": \"$BUILDINFO-$REPO_NAME\", \"color\": \"#36a64f\", \"icon_emoji\": \":checkered_flag:\"}" "$SLACK" > /dev/null
    fi
}

download_and_unpack_generic() {
    FILE=$1
    PACKAGE=$2
    URL=$3
    UNPACK=$4
    minisep $PACKAGE
    if [ -f $FILE ];
    then
        microsep "File $FILE already exists - skipping."
    else
        MAZFILE_LOCAL=false
        if [[ "x$LOCALCDN" != "x" ]]; then
            if [ -f $LOCALCDN/$FILE ]; then
                microsep "Using local file"
                MAZFILE_LOCAL=true
                ln -s $LOCALCDN/$FILE $FILE
            fi
        fi
        if [[ "x$MAZFILE_LOCAL" == "xfalse" ]]; then
            microsep "Downloading from $URL"
            wget --no-check-certificate -nv $URL -O $FILE > /dev/null
        fi
    fi
    if [ ! -d $PACKAGE ];
    then
        $UNPACK $FILE > /dev/null 
    fi    

}

download_and_unpack_tar_gz() {
    download_and_unpack_generic $1.tar.gz $1 $2 "tar xzvf"
}

check_ldd() {
    minisep "Checking LDD $1"
    LIB_SO=$1
    LIB_NAME=$(basename "$LIB_SO")
    ls -lah $LIB_SO*
    microsep "ldd"
    pushd $(dirname "$LIB_SO")
    file $LIB_SO | tee $TE_LIBS_LOGS/$LIB_NAME.file.log 
    ldd $LIB_SO | tee $TE_LIBS_LOGS/$LIB_NAME.ldd.log
    popd
    microsep "readelf"
    readelf -d $LIB_SO | tee $TE_LIBS_LOGS/$LIB_NAME.readelf.log
    microsep "objdump"
    objdump --syms $LIB_SO | grep -i debug || echo "no debugging symbols in $LIB_SO" | tee $TE_LIBS_LOGS/$LIB_NAME.objdump.debug.log
    minisep
}

# arg1 - project name used for logs
# arg2 - configure argument
# arg3 - false if no autoconf
install_raw() {
    if [[ "x$MAZCCFLAGS" == "x" ]]; then MAZCCFLAGS="-O3 -DNDEBUG -fPIC"; fi
    find . -exec touch {} \;
    if [[ "x$3" != "xfalse" ]]; then
    (autoconf || microsep "nothing to do - autoconf") &> $TE_LIBS_LOGS/$1.autoconf.log
    (automake || microsep "nothing to do - automake") &> $TE_LIBS_LOGS/$1.automake.log
    fi
    chmod +x ./configure
    echo cd `pwd` >> $TE_LIBS_LOGS/__all_commands.txt
    echo CPPFLAGS=\"-I$TE_LIBS/include\" LDFLAGS=\"-I$TE_LIBS/include -L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ $EXTRA_CPPFLAGS\" CFLAGS=\"$MAZCCFLAGS\" CXXFLAGS=\"$MAZCCFLAGS\" ./configure --prefix=$TE_LIBS $2 >> $TE_LIBS_LOGS/__all_commands.txt
    CPPFLAGS="-I$TE_LIBS/include" LDFLAGS="-I$TE_LIBS/include -L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ $EXTRA_CPPFLAGS" CFLAGS="$MAZCCFLAGS" CXXFLAGS="$MAZCCFLAGS" ./configure --prefix=$TE_LIBS $2 2>&1 | tee $TE_LIBS_LOGS/$1.configure.log | $TRIMMER
    find . -exec touch {} \;
    make 2>&1 | tee $TE_LIBS_LOGS/$1.make.log | $TRIMMER
    # chmod -R o+w ./* > /dev/null
    (sudo make install 2>&1 || microsep "nothing to do - make install") | tee $TE_LIBS_LOGS/$1.make.install.log | $TRIMMER
    #sudo make check
    sudo ldconfig
}

install_raw_alt() {
    if [[ "x$MAZCCFLAGS" == "x" ]]; then MAZCCFLAGS="-O3 -DNDEBUG -fPIC"; fi
    find . -exec touch {} \;
    autoconf > $TE_LIBS_LOGS/$1.autoconf.log 2>&1
    echo cd `pwd` >> $TE_LIBS_LOGS/__all_commands.txt
    echo LDFLAGS=\"-L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ -Wl,-rpath -Wl,$TE_LIBS/lib\" CFLAGS=\"$MAZCCFLAGS\" CXXFLAGS=\"$MAZCCFLAGS\" ./configure --prefix=$TE_LIBS $2 >> $TE_LIBS_LOGS/__all_commands.txt 
    LDFLAGS="-L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ -Wl,-rpath -Wl,$TE_LIBS/lib" CFLAGS="$MAZCCFLAGS" CXXFLAGS="$MAZCCFLAGS" ./configure --prefix=$TE_LIBS $2 > $TE_LIBS_LOGS/$1.configure.log 2>&1
    make 2>&1 | tee $TE_LIBS_LOGS/$1.make.log | tail -n 30
    sudo make altinstall 2>&1 | tee $TE_LIBS_LOGS/$1.make.install.log | $TRIMMER
    #sudo make check
    sudo ldconfig
}

install_dep_with_autoconf() {
    cd $TE_LIBS
    download_and_unpack_tar_gz $1 $2
    cd $1
    install_raw "$1" "$3"
}

install_dep() {
    cd $TE_LIBS
    download_and_unpack_tar_gz $1 $2
    cd $1
    install_raw "$1" "$3" "false"
}

safergitbitbucket() {
    export PARAMIDRSA=$1
    export PARAMCMD=$2

    BITBUCKET=bitbucket.org
    if [[ "x$PARAMIDRSA" != "x" ]]; then
        sudo -E ssh-agent bash -c "ssh-add $PARAMIDRSA; git clone $GITDEPTH git@$BITBUCKET:$PARAMCMD"
    else
        git clone $GITDEPTH git@$BITBUCKET:$PARAMCMD
    fi
}

vcspull() {
    export PARAMIDRSA=$1
    export PARAMREPO=$2

    echo "Executing: git clone $GITDEPTH $PARAMREPO"
    FAILED=
    if [[ "x$PARAMIDRSA" != "x" ]]; then
        sudo -E ssh-agent bash -c "ssh-add $PARAMIDRSA; git clone $GITDEPTH $PARAMREPO" || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            sudo -E ssh-agent bash -c "ssh-add $PARAMIDRSA; git clone $GITDEPTH $PARAMREPO" || FAILED=true
        fi
    else
        git clone $GITDEPTH $PARAMREPO || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            git clone $GITDEPTH $PARAMREPO || FAILED=true
        fi
    fi
}
