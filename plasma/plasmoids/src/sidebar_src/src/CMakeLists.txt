add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_io.gitgud.catpswin56.private.sidebar\")

kcoreaddons_add_plugin(io.gitgud.catpswin56.private.sidebar SOURCES groupingcontainment.cpp INSTALL_NAMESPACE "plasma/applets")
target_link_libraries(io.gitgud.catpswin56.private.sidebar
    Qt::Gui
    Qt::Quick
    Qt::DBus
    Qt::Widgets
    Plasma::Plasma
    Plasma::Plasma5Support
    KF6::XmlGui
    KF6::I18n
)

add_subdirectory(container)
