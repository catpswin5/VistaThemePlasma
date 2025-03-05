cmake_minimum_required(VERSION 3.16)

project(quicklaunch)

set(QT_MIN_VERSION "6.7.0")
set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMFindQmlModule)
include(ECMQmlModule)

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Quick
    Core
    QuickControls2
    Core5Compat
)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    I18n
    Kirigami
    KIO
    Notifications
)

ecm_find_qmlmodule(org.kde.kirigami REQUIRED)

find_package(Plasma REQUIRED)
find_package(PlasmaQuick ${PROJECT_DEP_VERSION} REQUIRED)

add_subdirectory(src)

ki18n_install(po)
