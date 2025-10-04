add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_io.gitgud.catpswin56.sidebar\")

if (Qt6_VERSION VERSION_GREATER_EQUAL "6.8.0")
    set(private_code_option  "PRIVATE_CODE")
endif()

add_library(io.gitgud.catpswin56.sidebar MODULE sidebar.cpp)
qt_generate_wayland_protocol_client_sources(io.gitgud.catpswin56.sidebar
    FILES
        "${PLASMA_WAYLAND_PROTOCOLS_DIR}/plasma-shell.xml"
        "${Wayland_DATADIR}/wayland.xml"
    ${private_code_option}
)

target_link_libraries(io.gitgud.catpswin56.sidebar
                      Wayland::Client
                      Qt6::Gui
                      Qt6::Quick
                      Qt6::Widgets
                      LayerShellQt::Interface
                      Plasma::Plasma
                      Plasma::PlasmaQuick
                      KF6::I18n
                      KF6::WindowSystem
                      KF6::XmlGui
                      KF6::ConfigCore
                      KF6::ConfigGui
                      KF6::CoreAddons)


include_directories(/usr/include/Plasma /usr/include/PlasmaQuick /usr/include/KF6/KConfigCore/ /usr/include/KF6/KConfig/ /usr/include/KF6/KCoreAddons/)

install(TARGETS io.gitgud.catpswin56.sidebar DESTINATION ${KDE_INSTALL_PLUGINDIR}/plasma/applets)
