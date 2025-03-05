ecm_add_qml_module(quicklaunchplugin URI io.gitgud.catpswin56.private.quicklaunch)
target_sources(quicklaunchplugin PRIVATE
    quicklaunch_p.cpp
    quicklaunchplugin.cpp
)
target_link_libraries(quicklaunchplugin PRIVATE
    Qt::Core
    Qt::Qml
    KF6::KIOCore
    KF6::KIOWidgets
    KF6::Notifications
)
ecm_finalize_qml_module(quicklaunchplugin)
