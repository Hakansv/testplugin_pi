# ---------------------------------------------------------------------------
# Author:      Pavel Kalian (Based on the work of Sean D'Epagnier) Copyright:   2014 License:     GPLv3+
# ---------------------------------------------------------------------------

set(SAVE_CMLOC ${CMLOC})
set(CMLOC "PluginInstall: ")

if(OCPN_FLATPAK_CONFIG)
    return()
endif(OCPN_FLATPAK_CONFIG)

if(NOT APPLE)
    target_link_libraries(${PACKAGE_NAME} ${wxWidgets_LIBRARIES} ${EXTRA_LIBS})
endif(NOT APPLE)

if(WIN32)
    if(MSVC)
        # TARGET_LINK_LIBRARIES(${PACKAGE_NAME} gdiplus.lib glu32.lib)
        target_link_libraries(${PACKAGE_NAME} ${OPENGL_LIBRARIES})

        set(OPENCPN_IMPORT_LIB "${CMAKE_SOURCE_DIR}/api-16/opencpn.lib")
    endif(MSVC)

    if(MINGW)
        # assuming wxwidgets is compiled with unicode, this is needed for mingw headers
        add_definitions(" -DUNICODE")
        target_link_libraries(${PACKAGE_NAME} ${OPENGL_LIBRARIES})
        # SET(OPENCPN_IMPORT_LIB "${PARENT}.dll")
        set(CMAKE_SHARED_LINKER_FLAGS "-L../buildwin")
        # target_link_libraries(${PACKAGE_NAME} ${OPENGL_LIBRARIES})
        set(OPENCPN_IMPORT_LIB "${CMAKE_SOURCE_DIR}/api-16/libopencpn.dll.a")
        if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            message(STATUS "${CMLOC}Will ensure library is stripped of all symbols")
            set(MINGW_LIBRARY_NAME "lib${PACKAGE_NAME}.dll")
            message(STATUS "${CMLOC}Library name: ${MINGW_LIBRARY_NAME}")
            #find_program(STRIP_UTIL NAMES strip REQUIRED)
            add_custom_command(
                TARGET ${PACKAGE_NAME}
                POST_BUILD
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                DEPENDS ${PACKAGE_NAME}
                COMMENT " Running post build action on ${lib_name}."
                COMMAND ls -la ${MINGW_LIBRARY_NAME}
            )
        endif(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    endif(MINGW)

    target_link_libraries(${PACKAGE_NAME} ${OPENCPN_IMPORT_LIB})
endif(WIN32)

if(UNIX)
    if(PROFILING)
        find_library(
            GCOV_LIBRARY
            NAMES gcov
            PATHS /usr/lib/gcc/i686-pc-linux-gnu/4.7)

        set(EXTRA_LIBS ${EXTRA_LIBS} ${GCOV_LIBRARY})
    endif(PROFILING)
endif(UNIX)

if(APPLE)
    install(
        TARGETS ${PACKAGE_NAME}
        RUNTIME
        LIBRARY DESTINATION OpenCPN.app/Contents/PlugIns)
    if(EXISTS ${PROJECT_SOURCE_DIR}/data)
        install(DIRECTORY data DESTINATION OpenCPN.app/Contents/SharedSupport/plugins/${PACKAGE_NAME})
    endif()

    find_package(ZLIB REQUIRED)
    target_link_libraries(${PACKAGE_NAME} ${ZLIB_LIBRARIES})

endif(APPLE)

if(UNIX AND NOT APPLE AND NOT QT_ANDROID)
    find_package(BZip2 REQUIRED)
    include_directories(${BZIP2_INCLUDE_DIR})
    find_package(ZLIB REQUIRED)
    include_directories(${ZLIB_INCLUDE_DIR})
    target_link_libraries(${PACKAGE_NAME} ${BZIP2_LIBRARIES} ${ZLIB_LIBRARY})
endif(UNIX AND NOT APPLE AND NOT QT_ANDROID)

set(PARENT opencpn)

# Based on code from nohal
if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX ${TENTATIVE_PREFIX})
endif(NOT CMAKE_INSTALL_PREFIX)

message(STATUS "${CMLOC}*** Will install to ${CMAKE_INSTALL_PREFIX}  ***")
set(PREFIX_DATA share)
set(PREFIX_PKGDATA ${PREFIX_DATA}/${PACKAGE_NAME})
# set(PREFIX_LIB "${CMAKE_INSTALL_PREFIX}/${LIB_INSTALL_DIR}")
set(PREFIX_LIB lib)

if(WIN32)
    message(STATUS "${CMLOC}Install Prefix: ${CMAKE_INSTALL_PREFIX}")
    set(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/../OpenCPN)
    if(CMAKE_CROSSCOMPILING)
        install(TARGETS ${PACKAGE_NAME} RUNTIME DESTINATION "plugins")
        set(INSTALL_DIRECTORY "plugins/${PACKAGE_NAME}")
    else(CMAKE_CROSSCOMPILING)
        install(TARGETS ${PACKAGE_NAME} RUNTIME DESTINATION "plugins")
        set(INSTALL_DIRECTORY "plugins\\\\${PACKAGE_NAME}")
    endif(CMAKE_CROSSCOMPILING)

    if(EXISTS ${PROJECT_SOURCE_DIR}/data)
        install(DIRECTORY data DESTINATION "${INSTALL_DIRECTORY}")
        message(STATUS "${CMLOC}Install Data: ${INSTALL_DIRECTORY}")
    endif(EXISTS ${PROJECT_SOURCE_DIR}/data)

    # fix for missing dll's FILE(GLOB gtkdll_files "${CMAKE_CURRENT_SOURCE_DIR}/buildwin/gtk/*.dll") INSTALL(FILES ${gtkdll_files} DESTINATION ".") FILE(GLOB expatdll_files
    # "${CMAKE_CURRENT_SOURCE_DIR}/buildwin/expat-2.1.0/*.dll") INSTALL(FILES ${expatdll_files} DESTINATION ".")

endif(WIN32)

if(UNIX AND NOT APPLE)
    set(PREFIX_PARENTDATA ${PREFIX_DATA}/${PARENT})
    set(PREFIX_PARENTLIB ${PREFIX_LIB}/${PARENT})
    message(STATUS "${CMLOC}PREFIX_PARENTLIB: ${PREFIX_PARENTLIB}")
    install(
        TARGETS ${PACKAGE_NAME}
        RUNTIME
        LIBRARY DESTINATION ${PREFIX_PARENTLIB})

    if(EXISTS ${PROJECT_SOURCE_DIR}/data)
        install(DIRECTORY data DESTINATION ${PREFIX_PARENTDATA}/plugins/${PACKAGE_NAME})
        message(STATUS "${CMLOC}Install data: ${PREFIX_PARENTDATA}/plugins/${PACKAGE_NAME}")
    endif()
    if(EXISTS ${PROJECT_SOURCE_DIR}/UserIcons)
        install(DIRECTORY UserIcons DESTINATION ${PREFIX_PARENTDATA}/plugins/${PACKAGE_NAME})
        set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${PROJECT_SOURCE_DIR}/script/postinst")
        set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${PROJECT_SOURCE_DIR}/script/postinst")
        message(STATUS "${CMLOC}Install UserIcons: ${PREFIX_PARENTDATA}/plugins/${PACKAGE_NAME}")
    endif()
endif(UNIX AND NOT APPLE)

if(APPLE)
    # For Apple build, we need to copy the "data" directory contents to the build directory, so that the packager can pick them up.
    if(NOT EXISTS "${PROJECT_BINARY_DIR}/data/")
        file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/data/")
        message("Generating data directory")
    endif()

    file(
        GLOB_RECURSE PACKAGE_DATA_FILES
        LIST_DIRECTORIES true
        ${CMAKE_SOURCE_DIR}/data/*)

    foreach(_currentDataFile ${PACKAGE_DATA_FILES})
        message(STATUS "${CMLOC}copying: ${_currentDataFile}")
        file(COPY ${_currentDataFile} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/data)
    endforeach(_currentDataFile)

    if(EXISTS ${PROJECT_SOURCE_DIR}/UserIcons)
        file(
            GLOB_RECURSE PACKAGE_DATA_FILES
            LIST_DIRECTORIES true
            ${CMAKE_SOURCE_DIR}/UserIcons/*)

        foreach(_currentDataFile ${PACKAGE_DATA_FILES})
            message(STATUS "${CMLOC}copying: ${_currentDataFile}")
            file(COPY ${_currentDataFile} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/UserIcons)
        endforeach(_currentDataFile)
    endif()

    install(
        TARGETS ${PACKAGE_NAME}
        RUNTIME
        LIBRARY DESTINATION OpenCPN.app/Contents/PlugIns)
    message(STATUS "${CMLOC}Install Target: OpenCPN.app/Contents/PlugIns")

endif(APPLE)

set(CMLOC ${SAVE_CMLOC})
