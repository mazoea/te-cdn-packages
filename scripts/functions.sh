#!/bin/bash
#
# part of Mazoea TE build pipeline
#

export PATH=$PATH:/usr/sbin:/sbin


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

if [[ "x$MAZ_MAKE_JOBS" == "x" ]]; then
    if [[ -n "$(command -v nproc)" ]]; then
        MAZ_MAKE_JOBS="-j$(nproc)"
    else
        MAZ_MAKE_JOBS="-j2"
    fi
fi

# if [[ "x$SLACK" == "x" ]]; then
#     echo '$SLACK' not set - will be ignored!
# fi

if [[ "x$TE_LIBS_LOGS" == "x" ]]; then
    export TE_LIBS_LOGS=/tmp/
fi
mkdir -p $TE_LIBS_LOGS || true

# echo "Using $TE_LIBS_LOGS as logging directory"
if [[ "x$TE_LIBS" != "x" ]]; then
    mkdir -p $TE_LIBS || true
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

apply_warning_patches() {
    local LOCAL_PACKAGE="$1"
    local LOCAL_FILE

    case "$LOCAL_PACKAGE" in
        libpng-*)
            LOCAL_FILE=contrib/libtests/pngstest.c
            if [[ -f "$LOCAL_FILE" ]]; then
                if grep -q 'char        tmpfile_name\[32\];' "$LOCAL_FILE"; then
                    microsep "Patching $LOCAL_PACKAGE temp file buffer"
                    sed -i 's/char        tmpfile_name\[32\];/char        tmpfile_name[64];/' "$LOCAL_FILE"
                fi
                if grep -q 'char name\[32\];' "$LOCAL_FILE"; then
                    microsep "Patching $LOCAL_PACKAGE output name buffer"
                    sed -i 's/char name\[32\];/char name[64];/' "$LOCAL_FILE"
                fi
                if grep -q 'sprintf(name, "%s%d.png", tmpf, ++counter);' "$LOCAL_FILE"; then
                    microsep "Patching $LOCAL_PACKAGE output name formatting"
                    sed -i 's/sprintf(name, "%s%d.png", tmpf, ++counter);/snprintf(name, sizeof name, "%s%d.png", tmpf, ++counter);/' "$LOCAL_FILE"
                fi
            fi
            ;;
        freetype-*)
            LOCAL_FILE=src/truetype/ttgload.c
            if [[ -f "$LOCAL_FILE" ]] && \
               grep -q 'loader->stream = &inc_stream;' "$LOCAL_FILE" && \
               ! grep -q 'loader->stream = face->root.stream;' "$LOCAL_FILE"; then
                microsep "Patching $LOCAL_PACKAGE incremental stream restore"
                sed -i '/^[[:space:]]*if ( glyph_data_loaded )/i\
    /* restore the original stream */\
    loader->stream = face->root.stream;\
' "$LOCAL_FILE"
            fi
            ;;
    esac
}

# arg1 - project name used for logs
# arg2 - configure argument
# arg3 - false if no autoconf
install_raw() {
    if [[ "x$MAZ_VERBOSE_MAKE" == "xtrue" ]]; then
        LOCAL_TRIMMER="cat"
    else
        LOCAL_TRIMMER="$TRIMMER"
    fi

    if [[ "x$MAZCCFLAGS" == "x" ]]; then MAZCCFLAGS="-O3 -DNDEBUG -fPIC"; fi

    # Best-effort refresh of config.guess and config.sub to support new
    # architectures. Tolerant of upstream errors (e.g. 502 from gitweb): on
    # failure the existing file is kept untouched so the build can proceed.
    for file in config.guess config.sub; do
        URL="https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=$file;hb=HEAD"
        if [ -f "$file" ]; then
            TARGET="$file"
        elif [ -f "config/$file" ]; then
            TARGET="config/$file"
        else
            continue
        fi
        echo "Refreshing $TARGET..."
        if wget --no-check-certificate -nv "$URL" -O "$TARGET.new" && [ -s "$TARGET.new" ]; then
            mv "$TARGET.new" "$TARGET"
        else
            echo "  refresh failed; keeping existing $TARGET"
            rm -f "$TARGET.new"
        fi
    done

    find . -exec touch {} \;
    if [[ "x$3" != "xfalse" ]]; then
    (autoconf || microsep "nothing to do - autoconf") &> $TE_LIBS_LOGS/$1.autoconf.log
    (automake || microsep "nothing to do - automake") &> $TE_LIBS_LOGS/$1.automake.log
    fi
    chmod +x ./configure
    echo cd `pwd` >> $TE_LIBS_LOGS/__all_commands.txt
    echo CPPFLAGS=\"-I$TE_LIBS/include\" LDFLAGS=\"-I$TE_LIBS/include -L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ $EXTRA_CPPFLAGS\" CFLAGS=\"$MAZCCFLAGS\" CXXFLAGS=\"$MAZCCFLAGS\" ./configure --prefix=$TE_LIBS $2 >> $TE_LIBS_LOGS/__all_commands.txt
    CPPFLAGS="-I$TE_LIBS/include" LDFLAGS="-I$TE_LIBS/include -L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ $EXTRA_CPPFLAGS" CFLAGS="$MAZCCFLAGS" CXXFLAGS="$MAZCCFLAGS" ./configure --prefix=$TE_LIBS $2 2>&1 | tee $TE_LIBS_LOGS/$1.configure.log | $LOCAL_TRIMMER
    find . -exec touch {} \;
    make $MAZ_MAKE_JOBS 2>&1 | tee $TE_LIBS_LOGS/$1.make.log | $LOCAL_TRIMMER
    # chmod -R o+w ./* > /dev/null
    (make install 2>&1 || microsep "nothing to do - make install") | tee $TE_LIBS_LOGS/$1.make.install.log | $LOCAL_TRIMMER
    #make check
    if [[ -n "$(command -v ldconfig)" ]]; then
        ldconfig || microsep "ldconfig failed - continuing"
    elif [[ -x "/sbin/ldconfig" ]]; then
        /sbin/ldconfig || microsep "ldconfig failed - continuing"
    else
        microsep "ldconfig not available - skipping"
    fi
}

install_raw_alt() {
    if [[ "x$MAZ_VERBOSE_MAKE" == "xtrue" ]]; then
        LOCAL_TRIMMER="cat"
    else
        LOCAL_TRIMMER="$TRIMMER"
    fi

    if [[ "x$MAZCCFLAGS" == "x" ]]; then MAZCCFLAGS="-O3 -DNDEBUG -fPIC"; fi
    find . -exec touch {} \;
    autoconf > $TE_LIBS_LOGS/$1.autoconf.log 2>&1
    echo cd `pwd` >> $TE_LIBS_LOGS/__all_commands.txt
    echo LDFLAGS=\"-L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ -Wl,-rpath -Wl,$TE_LIBS/lib\" CFLAGS=\"$MAZCCFLAGS\" CXXFLAGS=\"$MAZCCFLAGS\" ./configure --prefix=$TE_LIBS $2 >> $TE_LIBS_LOGS/__all_commands.txt
    LDFLAGS="-L$TE_LIBS/lib -Wl,-rpath -Wl,./ -Wl,-rpath -Wl,../ -Wl,-rpath -Wl,$TE_LIBS/lib" CFLAGS="$MAZCCFLAGS" CXXFLAGS="$MAZCCFLAGS" ./configure --prefix=$TE_LIBS $2 > $TE_LIBS_LOGS/$1.configure.log 2>&1
    make $MAZ_MAKE_JOBS 2>&1 | tee $TE_LIBS_LOGS/$1.make.log | $LOCAL_TRIMMER
    make altinstall 2>&1 | tee $TE_LIBS_LOGS/$1.make.install.log | $LOCAL_TRIMMER
    # make check
    if [[ -n "$(command -v ldconfig)" ]]; then
        ldconfig || microsep "ldconfig failed - continuing"
    elif [[ -x "/sbin/ldconfig" ]]; then
        /sbin/ldconfig || microsep "ldconfig failed - continuing"
    else
        microsep "ldconfig not available - skipping"
    fi
}

install_dep_with_autoconf() {
    cd $TE_LIBS
    download_and_unpack_tar_gz $1 $2
    cd $1
    apply_warning_patches "$1"
    install_raw "$1" "$3"
}

install_dep() {
    cd $TE_LIBS
    download_and_unpack_tar_gz $1 $2
    cd $1
    apply_warning_patches "$1"
    install_raw "$1" "$3" "false"
}

vcspull() {
    export PARAMIDRSA=$1
    export PARAMREPO=$2

    echo "Executing: git clone $GITDEPTH $PARAMREPO"
    FAILED=
    if [[ "x$PARAMIDRSA" != "x" ]]; then
        ssh-agent bash -c "ssh-add $PARAMIDRSA; git clone -q $GITDEPTH $PARAMREPO" || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            FAILED=
            ssh-agent bash -c "ssh-add $PARAMIDRSA; git clone $GITDEPTH $PARAMREPO" || FAILED=true
        fi
    else
        git clone -q $GITDEPTH $PARAMREPO || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            FAILED=
            git clone $GITDEPTH $PARAMREPO || FAILED=true
        fi
    fi

    if [[ "x$FAILED" == "xtrue" ]]; then
        exit 1
    fi
}

vcspush() {
    export PARAMIDRSA=$1
    export PARAMREMOTE=$2
    export PARAMBRANCH=$3

    echo "Executing: git push $PARAMREMOTE $PARAMBRANCH"
    FAILED=
    if [[ "x$PARAMIDRSA" != "x" ]]; then
        ssh-agent bash -c "ssh-add $PARAMIDRSA; git push $PARAMREMOTE $PARAMBRANCH" || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            FAILED=
            ssh-agent bash -c "ssh-add $PARAMIDRSA; git push $PARAMREMOTE $PARAMBRANCH" || FAILED=true
        fi
    else
        git push $PARAMREMOTE $PARAMBRANCH || FAILED=true
        if [[ "x$FAILED" == "xtrue" ]]; then
            FAILED=
            git push $PARAMREMOTE $PARAMBRANCH || FAILED=true
        fi
    fi

    if [[ "x$FAILED" == "xtrue" ]]; then
        exit 1
    fi
}
