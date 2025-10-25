## For Plasma end users
cmake_minimum_required(VERSION 3.16)

project(loginsessions)
find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)


if(PLASMA_X11_DEFAULT_SESSION)
   set(PLASMA_X11_DESKTOP_FILENAME vistathemeplasma.desktop CACHE INTERNAL "Filename for Plasma X11 session")
   set(PLASMA_WAYLAND_DESKTOP_FILENAME vistathemeplasmawayland.desktop CACHE INTERNAL "Filename for Plasma Wayland session")
else()
   set(PLASMA_X11_DESKTOP_FILENAME vistathemeplasmax11.desktop CACHE INTERNAL "Filename for Plasma X11 session")
   set(PLASMA_WAYLAND_DESKTOP_FILENAME vistathemeplasma.desktop CACHE INTERNAL "Filename for Plasma Wayland session")
endif()

configure_file(startvtp.cmake ${CMAKE_CURRENT_BINARY_DIR}/startvtp)
install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/startvtp
	PERMISSIONS OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
        DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
configure_file(startvtp-wayland.cmake ${CMAKE_CURRENT_BINARY_DIR}/startvtp-wayland)
install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/startvtp-wayland
	PERMISSIONS OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
        DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})

configure_file(vistathemeplasmax11.desktop.cmake ${CMAKE_CURRENT_BINARY_DIR}/${PLASMA_X11_DESKTOP_FILENAME})
install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PLASMA_X11_DESKTOP_FILENAME}
        DESTINATION ${KDE_INSTALL_DATADIR}/xsessions
)

configure_file(vistathemeplasmawayland.desktop.cmake ${CMAKE_CURRENT_BINARY_DIR}/${PLASMA_WAYLAND_DESKTOP_FILENAME})
install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PLASMA_WAYLAND_DESKTOP_FILENAME}
        DESTINATION ${KDE_INSTALL_DATADIR}/wayland-sessions
)
