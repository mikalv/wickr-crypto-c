# Bootstrap support for building required dependencies automatically

cmake_minimum_required(VERSION 2.8.11)

if(POLICY CMP0020)
    cmake_policy(SET CMP0020 NEW)
endif()

set(OSSL_VERSION "1.0.2l")
set(OSSL_HASH "ce07195b659e75f4e1db43552860070061f156a98bb37b672b101ba6e3ddf30c")
set(CMAKE_BUILD_TYPE Release)
# Create PORTS_PREFIX variable with spaces escaped
string(REGEX REPLACE " " "\ " PORTS_PREFIX "${CMAKE_CURRENT_BINARY_DIR}")
set(PORTS_SCRIPTS "${CMAKE_CURRENT_SOURCE_DIR}")
set(ENV{MACOSX_DEPLOYMENT_TARGET} "10.10")

include(ExternalProject)

# for windows we have to build a standard openssl distro to use
# openssl configure build requires perl to be installed on windows.

if(WIN32)
    if(PORTS_ARCH MATCHES "x86_64")
        ExternalProject_add(wickr-openssl
            PREFIX "${PORTS_PREFIX}"
            URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
	    URL_HASH
            SHA256=${OSSL_HASH}            
	    CONFIGURE_COMMAND perl Configure VC-WIN64A enable-static-engine no-static shared
            BUILD_COMMAND ms\\do_win64a.ba
            INSTALL_COMMAND nmake -f ms\\nt.mak INSTALLTOP=../.. install
            BUILD_IN_SOURCE 1
        )
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libeay64.lib" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/ssleay64.lib" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/src/wickr-openssl/tmp64/app.pdb" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/src/wickr-openssl/tmp64/lib.pdb" DESTINATION lib/${CMAKE_BUILD_TYPE})
    else()
        ExternalProject_add(wickr-openssl
            PREFIX "${PORTS_PREFIX}"
            URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}        
    	    CONFIGURE_COMMAND perl Configure VC-WIN32 enable-static-engine no-static shared
            BUILD_COMMAND ms\\do_nasm.bat
            INSTALL_COMMAND nmake -f ms\\nt.mak INSTALLTOP=../.. install
            BUILD_IN_SOURCE 1
        )
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libeay32.lib" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/ssleay32.lib" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/src/wickr-openssl/tmp32/app.pdb" DESTINATION lib/${CMAKE_BUILD_TYPE})
        INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/src/wickr-openssl/tmp32/lib.pdb" DESTINATION lib/${CMAKE_BUILD_TYPE})
    endif()

elseif(APPLE AND IOS)
    if(IOS_ARCH MATCHES "armv7")
        message("openssl: iOS: arch=armv7")
        message("openssl: CROSS_TOP = ${CROSS_TOP}")
        ExternalProject_add(wickr-openssl
            PREFIX "${PORTS_PREFIX}"
            URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}
            CONFIGURE_COMMAND "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} ./Configure --prefix=${PORTS_PREFIX} iphoneos-cross
            BUILD_COMMAND     "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make all
            INSTALL_COMMAND   "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make install_sw

            BUILD_IN_SOURCE 1
         )
    elseif(IOS_ARCH MATCHES "arm64")
        message("openssl: iOS: arch=arm64")
        set( ENV{IOS_ARCH} ${IOS_ARCH} )
        ExternalProject_add(wickr-openssl
            PREFIX "${PORTS_PREFIX}"
            URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}
            CONFIGURE_COMMAND "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} ./Configure --prefix=${PORTS_PREFIX} iphoneos-cross
            BUILD_COMMAND     "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make all
            INSTALL_COMMAND   "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make install_sw
            BUILD_IN_SOURCE 1
         )
    elseif(IOS_ARCH MATCHES "x86_64" OR IOS_ARCH MATCHES "i386")
        message("openssl: iOS: arch=x86_64")
        set( ENV{IOS_ARCH} ${IOS_ARCH} )
        ExternalProject_add(wickr-openssl
            PREFIX "${PORTS_PREFIX}"
            URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}
            CONFIGURE_COMMAND "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} "${PORTS_SCRIPTS}/openssl-configure-ios.sh ${PORTS_PREFIX}"
            BUILD_COMMAND     "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make
            INSTALL_COMMAND   "${PORTS_SCRIPTS}/setenv-ios.sh" ${IOS_ARCH} make all install_sw
            BUILD_IN_SOURCE 1
         )
    else()
        message("openssl: iOS: arch=undefined")
    endif()
    INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libcrypto.a" DESTINATION lib)
elseif(APPLE)
    ExternalProject_add(wickr-openssl
        PREFIX "${PORTS_PREFIX}"
        URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
        URL_HASH
        SHA256=${OSSL_HASH}
        CONFIGURE_COMMAND ./Configure no-static shared --prefix=${PORTS_PREFIX} darwin64-x86_64-cc
        BUILD_COMMAND make CC="${PORTS_SCRIPTS}/mac-clang.sh"
        INSTALL_COMMAND make install_sw
        BUILD_IN_SOURCE 1
    )
    INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libcrypto.a" DESTINATION lib)

elseif (ANDROID)
    if(ANDROID_ABI MATCHES "x86")
        ExternalProject_add(wickr-openssl
            PREFIX            "${PORTS_PREFIX}"
            URL               "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}
            CONFIGURE_COMMAND "${PORTS_SCRIPTS}/setenv-android-x86.sh" ./Configure no-static shared --prefix=${PORTS_PREFIX} android-x86
            BUILD_COMMAND     "${PORTS_SCRIPTS}/setenv-android-x86.sh" make depend && "${PORTS_SCRIPTS}/setenv-android-x86.sh" make all
            INSTALL_COMMAND   "${PORTS_SCRIPTS}/setenv-android-x86.sh" make install_sw
            BUILD_IN_SOURCE   1
        )
    else()
        ExternalProject_add(wickr-openssl
            PREFIX            "${PORTS_PREFIX}"
            URL               "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
            URL_HASH
            SHA256=${OSSL_HASH}
            CONFIGURE_COMMAND "${PORTS_SCRIPTS}/setenv-android.sh" ./Configure no-static shared --prefix=${PORTS_PREFIX} android-armv7
            BUILD_COMMAND     "${PORTS_SCRIPTS}/setenv-android.sh" make depend && "${PORTS_SCRIPTS}/setenv-android.sh" make all
            INSTALL_COMMAND   "${PORTS_SCRIPTS}/setenv-android.sh" make install_sw
            BUILD_IN_SOURCE   1
        )
    endif()
    INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libcrypto.a" DESTINATION lib)

# Many Unix platforms have openssl as a default system library, Apple doesnt.
elseif (UNIX)
    ExternalProject_add(wickr-openssl
        PREFIX "${PORTS_PREFIX}"
        URL "https://www.openssl.org/source/openssl-${OSSL_VERSION}.tar.gz"
        URL_HASH
        SHA256=${OSSL_HASH}        
        CONFIGURE_COMMAND ./Configure no-static shared --prefix=${PORTS_PREFIX} linux-x86_64-clang
        BUILD_COMMAND make
        INSTALL_COMMAND make install
        BUILD_IN_SOURCE 1
    )
    INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/lib/libcrypto.a" DESTINATION lib)
endif()
