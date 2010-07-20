#!/bin/sh -e

[ "z$TGT" = "z" ] && TGT=32
if [ "z$TGT" = "z32" ] ; then
    XX=xxxxxxxxxxxxxxxx32
elif [ "z$TGT" = "z64" ] ; then
    XX=xxxxxxxxxxxxxxxx64
fi
cd ~/src/
BLD="/comptel/ilink/$XX"
PRD="/comptel/ilink/local"
PATH="$PRD/bin:$BLD/bin:/usr/bin:/usr/contrib/bin:/usr/bin/X11:/usr/contrib/bin/X11:/opt/ssh/bin"
export PATH
LD_LIBRARY_PATH="$PRD/lib:$BLD/lib"
export LD_LIBRARY_PATH
MANPATH="$PRD/man/%L:$PRD/man:$BLD/man/%L:$BLD/man:$MANPATH"
export MANPATH
CPPFLAGS="-D_XOPEN_SOURCE=600"
export CPPFLAGS
CFLAGS=""
CXXFLAGS=""
CONFIG_SHELL=/usr/local/bin/bash
export CONFIG_SHELL
UNIX_STD=2003
export UNIX_STD
DST_PFX="$BLD"
CMI_LOG="$BLD/log"

if ! [ -d "$CMI_LOG" ] ; then
    echo "ERROR: build log directory $CMI_LOG doesn't exist" 1>&2
    exit 1
fi

cmi () {
    s="$1"
    shift
    [ -f "$CMI_LOG/$s"-ok ] && return 0
    echo "building $s..."
    [ -f "$s"a.tar.gz ] && t="$s"a.tar.gz || t="$s".tar.gz
    rm -rf "$s" ; gunzip < "$t" | tar xf -
    cd "$s"
    if [ "z$s" = "zgcc-3.3.6" ] && [ "z$2" = "z--enable-languages=c" ] ; then
        echo 'am_cv_func_iconv=${am_cv_func_iconv=no}' >>config.cache
        echo 'am_cv_func_iconv=${am_cv_func_iconv=no}' >>gcc/config.cache
    elif [ "z$s" = "zgcc-3.4.6" ] ; then
        if ! [ -f "$CMI_LOG/$s"-f77-ok ] ; then
            echo "  building $s-f77..."
            rm -rf "../$s-f77"
            cp -pr "../$s" "../$s-f77"
            cd "../$s-f77"
            CPPFLAGS=
            CXXFLAGS=
            CFLAGS=
            ./configure "$1" --enable-languages=f77 \
                >"$CMI_LOG/$s"-configure-f77.log 2>&1
            make -j 8 >"$CMI_LOG/$s"-make-f77.log 2>&1
            cp install-sh ia64-hp-hpux11.31/
            make install >"$CMI_LOG/$s"-install-f77.log 2>&1
            touch "$CMI_LOG/$s"-f77-ok
            echo "  installed $s-f77"
            cd "../$s/"
        fi
        CPPFLAGS="-D_XOPEN_SOURCE=600"
        CFLAGS="$CPPFLAGS"
        export CFLAGS
        CXXFLAGS="$CPPFLAGS"
        export CXXFLAGS
    elif [ "z$s" = "zbinutils-2.16.1" ] ; then
        echo 'ac_cv_lib_l_yywrap=${ac_cv_lib_l_yywrap=no}' \
            >>binutils/config.cache
        echo 'ac_cv_lib_l_yywrap=${ac_cv_lib_l_yywrap=no}' \
            >>gas/config.cache
    elif [ "z$s" = "zncurses-5.7" ] ; then
        patch configure <../ncurses-5.7-hpux.patch
    elif [ "z$s" = "zscreen-4.0.3" ] ; then
        patch misc.c <../screen-4.0.3-hpux.patch
        CFLAGS="$CPPFLAGS -DNLIST_DECLARED"
        export CFLAGS
    elif [ "z$s" = "zPython-2.6.4" ] ; then
#        CPPFLAGS="-D_XOPEN_SOURCE=600 -nostdinc -I$DST_PFX/include\
#        -I$DST_PFX/lib/gcc/ia64-hp-hpux11.31/3.4.6/include\
#        -I/usr/include -DHAVE_TERMIOS_H_BEFORE_SYS_TERMIO_Hi\
#        -DHAVE_NCURSES_NCURSES_H"
        CPPFLAGS="-D_XOPEN_SOURCE=600 -DHAVE_TERMIOS_H_BEFORE_SYS_TERMIO_H\
        -DHAVE_NCURSES_NCURSES_H"
        EXTRA_CFLAGS="$CPPFLAGS"
        export EXTRA_CFLAGS
        patch configure <../python-2.6.4-configure.patch
        patch setup.py <../python-2.6.4-setup.patch
        patch Include/pyport.h <../python-2.6.4-pyport.patch
        patch Include/py_curses.h <../python-2.6.4-curses.patch
        patch Modules/_curses_panel.c <../python-2.6.4-panel.patch
        patch Python/dynload_hpux.c <../python-2.6.4-shl_load.patch
        patch Lib/getpass.py <../python-2.6.4-getpass.patch
    elif [ "z$s" = "zautogen-5.10.1" ] ; then
        CPPFLAGS="-std=gnu89 -D_XOPEN_SOURCE=500"
        #perl -pi -wse 's/setjmp[.]h/setjmpshit.h/' configure
    elif [ "z$s" = "zguile-1.8.7" ] ; then
        #CPPFLAGS="$CPPFLAGS -D_PSTAT64 -mlp64"
        # 1.
        # guile wants chroot() and L_cuserid which are not available
        # in Xopen 6.0, only in 5.0:
        # 2.
        # gcc must use optimization, otherwise snarf-check-and-output-texi
        # overflows stack during guile-procedures.texi compilation
        CPPFLAGS="-D_XOPEN_SOURCE=500"
        CFLAGS="$CPPFLAGS -O2 -Wno-missing-braces"
        export CFLAGS
        CXXFLAGS="$CPPFLAGS -O2 -Wno-missing-braces"
        export CXXFLAGS
        patch libguile/gc.c <../guile-1.8.7-gc.patch
        patch libguile/posix.c <../guile-1.8.7-posix.patch
        patch configure <../guile-1.8.7-configure.patch
        #patch configure.in <../guile-1.8.7-configurein.patch
        #autoreconf >"$CMI_LOG/$s"-autoreconf.log 2>&1
    fi
    if [ -x Configure ] ; then CONFIGURE=./Configure
    elif [ -x configure ] ; then CONFIGURE=./configure
    else CONFIGURE=echo
    fi
    "$CONFIGURE" "$@" >"$CMI_LOG/$s"-configure.log 2>&1
    if [ "z$s" = "zgcc-3.3.6" ] && [ "z$2" = "z--enable-languages=c" ] ; then
        if [ "z$TGT" = "z64" ] ; then
            make bootstrap >"$CMI_LOG/$s"-make.log 2>&1
        else
            make bootstrap MAKE='make -j 8' >"$CMI_LOG/$s"-make.log 2>&1
        fi
    elif [ "z$s" = "zgcc-3.4.6" ] || [ "z$s" = "zgcc-3.3.6" ] ; then
        make MAKE='make -j 8' >"$CMI_LOG/$s"-make.log 2>&1
    elif [ "z$s" = "zguile-1.8.7" ] ; then
        perl -pi -wse 's/(-Wno-missing-braces)(\s+)(-Wall)/$3$2$1/'\
            libguile/Makefile
        make >"$CMI_LOG/$s"-make.log 2>&1
    else
        make >"$CMI_LOG/$s"-make.log 2>&1
    fi
    [ "z$s" = "zPython-2.6.4" ] && grep "Failed to build these modules" \
        "$CMI_LOG/$s"-make.log && exit 1
    if [ "z$CONFIGURE" = "zecho" ] ; then
        make install "$@" >"$CMI_LOG/$s"-install.log
    else
        make install >"$CMI_LOG/$s"-install.log 2>&1
    fi
    cd ..
    touch "$CMI_LOG/$s"-ok
    echo "installed $s"
    PATH="$PATH"
    export PATH
    CPPFLAGS="-D_XOPEN_SOURCE=600"
    export CPPFLAGS
    CFLAGS=
    CXXFLAGS=
    EXTRA_CFLAGS=
}

if [ "z$TGT" = "z64" ] ; then
    CC="cc -Wp,-H256000 +DD$TGT"
    export CC
fi

for s in binutils-2.16.1 bison-1.25 flex-2.5.4 m4-1.4.14 make-3.81 ; do
    cmi "$s" --prefix="$DST_PFX"
done

cmi gcc-3.3.6 --prefix="$DST_PFX" --enable-languages=c
unset CC || true
#termcap-1.3.1
for s in libiconv-1.13.1 sed-4.2.1 tar-1.22 gawk-3.1.6 \
flex-2.5.33 bison-2.4 \
autoconf-2.65 automake-1.11.1 ; do
    cmi "$s" --prefix="$DST_PFX"
done
cmi ncurses-5.7 --prefix="$DST_PFX" --without-cxx-binding \
    --without-ada --without-cxx --with-termlib --enable-sigwinch \
    --enable-overwrite --with-curses-h --without-termlib
cmi texinfo-4.13 --prefix="$DST_PFX"
cmi gcc-3.4.6 --prefix="$DST_PFX" --enable-languages=c,c++,java,objc
for s in diffutils-2.9 readline-6.1 screen-4.0.3 zlib-1.2.4 ; do
    cmi "$s" --prefix="$DST_PFX"
done
cmi bzip2-1.0.5 PREFIX=$DST_PFX
cmi openssl-0.9.8m --prefix="$DST_PFX" hpux64-ia64-gcc
for s in sqlite-3.6.23 Python-2.6.4 rsync-3.0.7 cvs-1.11.23 \
libtool-2.2.6b gmp-5.0.1 ; do
    cmi "$s" --prefix="$DST_PFX"
done
mv "$DST_PFX/bin/screen-4.0.3" "$DST_PFX/bin/screen-4.0.3.root"
cp "$DST_PFX/bin/screen-4.0.3.root" "$DST_PFX/bin/screen-4.0.3"
rm -f "$DST_PFX/bin/screen-4.0.3.root"
chmod u+w "$DST_PFX/lib/"*.*
for s in guile-1.8.7 autogen-5.10.1 ; do
    cmi "$s" --prefix="$DST_PFX"
done
cmi netcat-1.10.orig

# vi:set sw=4 et:
