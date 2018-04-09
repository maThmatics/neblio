greaterThan(QT_MAJOR_VERSION, 4) {
    QT += widgets
    DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0
}

# for boost 1.37, add -mt to the boost libraries
# use: qmake BOOST_LIB_SUFFIX=-mt
# for boost thread win32 with _win32 sufix
# use: BOOST_THREAD_LIB_SUFFIX=_win32-...
# or when linking against a specific BerkelyDB version: BDB_LIB_SUFFIX=-4.8

BOOST_LIB_SUFFIX=
windows:BOOST_INCLUDE_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/include/boost
windows:BOOST_LIB_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/lib
macx:BOOST_LIB_PATH=/usr/local/Cellar/boost/1.64.0_1/lib
windows:BDB_INCLUDE_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/include
windows:BDB_LIB_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/lib
macx:BDB_LIB_PATH=/usr/local/Cellar/berkeley-db\@4/4.8.30/lib/
windows:OPENSSL_INCLUDE_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/include/openssl
windows:OPENSSL_LIB_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/lib
macx:OPENSSL_LIB_PATH=/usr/local/opt/openssl/lib
MINIUPNPC_LIB_SUFFIX=-miniupnpc
windows:MINIUPNPC_INCLUDE_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/include
windows:MINIUPNPC_LIB_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/libc
macx:MINIUPNPC_INCLUDE_PATH=/usr/local/Cellar/miniupnpc/2.0.20170509/include
macx:MINIUPNPC_LIB_PATH=/usr/local/Cellar/miniupnpc/2.0.20170509/lib
macx:QRENCODE_INCLUDE_PATH=/usr/local/Cellar/qrencode/3.4.4/include
macx:QRENCODE_LIB_PATH=/usr/local/Cellar/qrencode/3.4.4/lib
macx:CURL_LIB_PATH=/usr/local/opt/curl/lib
windows:QRENCODE_INCLUDE_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/include
windows:QRENCODE_LIB_PATH=/home/build/Documents/mxe/usr/i686-w64-mingw32.static/libc

# Dependency library locations can be customized with:
#    BOOST_INCLUDE_PATH, BOOST_LIB_PATH, BDB_INCLUDE_PATH,
#    BDB_LIB_PATH, OPENSSL_INCLUDE_PATH and OPENSSL_LIB_PATH respectively

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# fixes an issue with boost 1.66 and the number of template parameters of basic_socket_acceptor
DEFINES += BOOST_ASIO_ENABLE_OLD_SERVICES
# TODO: Move to the new standard of boost as current code is deprecated

# use: qmake "RELEASE=1"
contains(RELEASE, 1) {
    # Mac: compile for maximum compatibility (10.5, 32-bit)
    macx:QMAKE_CXXFLAGS += -mmacosx-version-min=10.5 -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk

    !windows:!macx {
        # Linux: static link
        LIBS += -Wl,-Bstatic
    }
}


!win32 {
# for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
QMAKE_CXXFLAGS *= -fstack-protector-all
QMAKE_LFLAGS *= -fstack-protector-all
# We need to exclude this for Windows cross compile with MinGW 4.2.x, as it will result in a non-working executable!
# This can be enabled for Windows, when we switch to MinGW >= 4.4.x.
}
# for extra security (see: https://wiki.debian.org/Hardening)
QMAKE_CXXFLAGS *= -D_FORTIFY_SOURCE=2 -Wl,-z,relro -Wl,-z,now
# for extra security on Windows: enable ASLR and DEP via GCC linker flags
win32:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat
win32:QMAKE_LFLAGS *= -Wl,--large-address-aware -static
#win32:QMAKE_LFLAGS += -static-libgcc -static-libstdc++


# use: qmake "USE_QRCODE=1"
# libqrencode (http://fukuchi.org/works/qrencode/index.en.html) must be installed for support
contains(USE_QRCODE, 1) {
    message(Building with QRCode support)
    DEFINES += USE_QRCODE
    LIBS += -lqrencode
    windows:LIBS += -lpthread
}

# use: qmake "USE_UPNP=1" ( enabled by default; default)
#  or: qmake "USE_UPNP=0" (disabled by default)
#  or: qmake "USE_UPNP=-" (not supported)
# miniupnpc (http://miniupnp.free.fr/files/) must be installed for support
contains(USE_UPNP, -) {
    message(Building without UPNP support)
} else {
    message(Building with UPNP support)
    count(USE_UPNP, 0) {
        USE_UPNP=1
    }
    DEFINES += USE_UPNP=$$USE_UPNP STATICLIB
    INCLUDEPATH += $$MINIUPNPC_INCLUDE_PATH
    LIBS += $$join(MINIUPNPC_LIB_PATH,,-L,) -lminiupnpc
    win32:LIBS += -liphlpapi
}

# use: qmake "USE_DBUS=1" or qmake "USE_DBUS=0"
linux:count(USE_DBUS, 0) {
    USE_DBUS=1
}
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}

INCLUDEPATH += $$PWD/leveldb/include $$PWD/leveldb/helpers
macx: INCLUDEPATH += /usr/include /usr/local/opt/berkeley-db@4/include /usr/local/opt/boost/include /usr/local/opt/openssl/include
LIBS += $$PWD/leveldb/libleveldb.a $$PWD/leveldb/libmemenv.a
SOURCES += txdb-leveldb.cpp

!win32 {
    # we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
    genleveldb.commands = cd $$PWD/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a
} else {
    # make an educated guess about what the ranlib command is called
    isEmpty(QMAKE_RANLIB) {
        QMAKE_RANLIB = $$replace(QMAKE_STRIP, strip, ranlib)
    }
    LIBS += -lshlwapi
   # genleveldb.commands = cd $$PWD/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX TARGET_OS=OS_WINDOWS_CROSSCOMPILE $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a && $$QMAKE_RANLIB $$PWD/leveldb/libleveldb.a && $$QMAKE_RANLIB $$PWD/leveldb/libmemenv.a
}
genleveldb.target = $$PWD/leveldb/libleveldb.a
genleveldb.depends = FORCE
PRE_TARGETDEPS += $$PWD/leveldb/libleveldb.a
QMAKE_EXTRA_TARGETS += genleveldb
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/leveldb/libleveldb.a; cd $$PWD/leveldb ; $(MAKE) clean

# regenerate build.h
!windows|contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh ../share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

contains(USE_O3, 1) {
    message(Building O3 optimization flag)
    QMAKE_CXXFLAGS_RELEASE -= -O2
    QMAKE_CFLAGS_RELEASE -= -O2
    QMAKE_CXXFLAGS += -O3
    QMAKE_CFLAGS += -O3
}

*-g++-32 {
    message("32 platform, adding -msse2 flag")

    QMAKE_CXXFLAGS += -msse2
    QMAKE_CFLAGS += -msse2
}

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wno-ignored-qualifiers -Wformat -Wformat-security -Wno-unused-parameter -Wstack-protector


CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to qt/bitcoin.qrc under translations/
TRANSLATIONS = $$files(qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
    QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

# "Other files" to show in Qt Creator
OTHER_FILES += \
    doc/*.rst doc/*.txt doc/README README.md res/bitcoin-qt.rc

# platform specific defaults, if not overridden on command line
isEmpty(BOOST_LIB_SUFFIX) {
    macx:BOOST_LIB_SUFFIX = -mt
    windows:BOOST_LIB_SUFFIX = -mt
}

isEmpty(BOOST_THREAD_LIB_SUFFIX) {
    win32:BOOST_THREAD_LIB_SUFFIX = _win32$$BOOST_LIB_SUFFIX
    else:BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
}

isEmpty(BDB_LIB_PATH) {
    macx:BDB_LIB_PATH = /opt/local/lib/db48
}

isEmpty(BDB_LIB_SUFFIX) {
    macx:BDB_LIB_SUFFIX = -4.8
}

isEmpty(BDB_INCLUDE_PATH) {
    macx:BDB_INCLUDE_PATH = /opt/local/include/db48
}

isEmpty(BOOST_LIB_PATH) {
    macx:BOOST_LIB_PATH = /opt/local/lib
}

isEmpty(BOOST_INCLUDE_PATH) {
    #macx:BOOST_INCLUDE_PATH = /opt/local/include
    macx:BOOST_INCLUDE_PATH = /usr/local/include
}

windows:DEFINES += WIN32
windows:RC_FILE = qt/res/bitcoin-qt.rc

windows:!contains(MINGW_THREAD_BUGFIX, 0) {
    # At least qmake's win32-g++-cross profile is missing the -lmingwthrd
    # thread-safety flag. GCC has -mthreads to enable this, but it doesn't
    # work with static linking. -lmingwthrd must come BEFORE -lmingw, so
    # it is prepended to QMAKE_LIBS_QT_ENTRY.
    # It can be turned off with MINGW_THREAD_BUGFIX=0, just in case it causes
    # any problems on some untested qmake profile now or in the future.
    DEFINES += _MT BOOST_THREAD_PROVIDES_GENERIC_SHARED_MUTEX_ON_WIN
    QMAKE_LIBS_QT_ENTRY = -lmingwthrd $$QMAKE_LIBS_QT_ENTRY
}

macx:HEADERS += qt/macdockiconhandler.h qt/macnotificationhandler.h
macx:OBJECTIVE_SOURCES += qt/macdockiconhandler.mm qt/macnotificationhandler.mm
macx:LIBS += -framework Foundation -framework ApplicationServices -framework AppKit
macx:DEFINES += MAC_OSX MSG_NOSIGNAL=0
macx:ICON = qt/res/icons/bitcoin.icns
macx:TARGET = "neblio-Qt"
macx:QMAKE_CFLAGS_THREAD += -pthread
macx:QMAKE_LFLAGS_THREAD += -pthread
macx:QMAKE_CXXFLAGS_THREAD += -pthread

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
macx: LIBS += $$join(CURL_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX
# -lgdi32 has to happen after -lcrypto (see  #681)
windows:LIBS += -lws2_32 -lshlwapi -lmswsock -lole32 -loleaut32 -luuid -lgdi32
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX -lboost_regex$$BOOST_LIB_SUFFIX
windows:LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX
macx: LIBS += -lcurl

# For Fedora
unix:INCLUDEPATH += /usr/include/libdb4/
unix:LIBS        += -L/usr/lib64/libdb4/

contains(RELEASE, 1) {
    !windows:!macx {
        # Linux: turn dynamic linking back on for c/c++ runtime libraries
        LIBS += -Wl,-Bdynamic
    }
}

!windows:!macx {
    DEFINES += LINUX
    LIBS += -lrt -ldl
}

!win32:!macx {
    cURL_LIBS = $$system("pkg-config libcurl --libs")
    LIBS += $$cURL_LIBS
}
win32 {
    # for mxe
    cURL_LIBS = $$system("i686-w64-mingw32.static-pkg-config libcurl --libs")
    LIBS += $$cURL_LIBS
}
