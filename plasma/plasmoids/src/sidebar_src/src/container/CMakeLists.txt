set(groupedappletscontainer_SRCS
    groupedappletscontainer.cpp
)
ecm_qt_declare_logging_category(groupedappletscontainer_SRCS
    HEADER debug.h
    IDENTIFIER GROUPING_DEBUG
    CATEGORY_NAME catpswin56.sidebar
    DEFAULT_SEVERITY Info
    DESCRIPTION "Desktop Sidebar"
    EXPORT KDEPLASMAADDONS
)

kcoreaddons_add_plugin(io.gitgud.catpswin56.sidebar SOURCES ${groupedappletscontainer_SRCS} INSTALL_NAMESPACE "plasma/applets")
target_link_libraries(io.gitgud.catpswin56.sidebar
    Qt::Gui
    Qt::Quick
    Plasma::Plasma
    Plasma::PlasmaQuick
    KF6::XmlGui
    KF6::I18n
)
