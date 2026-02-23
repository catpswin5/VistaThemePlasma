add_subdirectory(login-sessions)
add_subdirectory(kcm)

if(NOT INSTALL_X11_COMPONENTS)
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/plasma/sddm/sddm-theme-mod DESTINATION ${CMAKE_INSTALL_PREFIX}/share/sddm/themes)
endif()

