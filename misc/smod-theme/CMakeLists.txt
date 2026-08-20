qt6_add_binary_resources(theme Assets.qrc)
install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/theme.rcc
    DESTINATION
        ${CMAKE_INSTALL_PREFIX}/share/smod/decorations/
    RENAME
        VistaAero.smod.rcc
)
