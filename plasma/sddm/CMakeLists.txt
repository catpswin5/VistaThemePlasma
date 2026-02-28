add_subdirectory(login-sessions)

if(NOT INSTALL_X11_COMPONENTS)
    add_subdirectory(kcm)
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/plasma/sddm/vista-theme-mod DESTINATION ${CMAKE_INSTALL_PREFIX}/share/sddm/themes)
endif()

