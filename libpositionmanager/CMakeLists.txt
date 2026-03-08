# kde there's no good reason to do this please
remove_definitions(-DQT_NO_CAST_TO_ASCII -DQT_NO_CAST_FROM_ASCII -DQT_USE_QSTRINGBUILDER)

set(positionmanagerplugin_SRCS
    positionmanager.h positionmanager.cpp
)

add_library(positionmanagerplugin SHARED ${positionmanagerplugin_SRCS})

target_link_libraries(positionmanagerplugin
    PRIVATE
        Qt6::Core
        Qt6::Widgets
        Qt6::Quick
)

ecm_add_qml_module(positionmanagerplugin
    URI "vistathemeplasma.positionmanager"
    VERSION 0.1
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES QtCore
)
ecm_finalize_qml_module(positionmanagerplugin)

install(TARGETS positionmanagerplugin ${KDE_INSTALL_TARGETS_DEFAULT_ARGS} LIBRARY NAMELINK_SKIP)


