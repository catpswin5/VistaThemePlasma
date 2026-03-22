add_subdirectory(src)

set(plasmoids
    io.gitgud.catpswin56.panel
    io.gitgud.catpswin56.battery
    io.gitgud.catpswin56.digitalclocklite
    io.gitgud.catpswin56.networkmanagement
    io.gitgud.catpswin56.volume
    io.gitgud.catpswin56.keyboardlayout

    io.gitgud.catpswin56.vistastart
    io.gitgud.catpswin56.quicklaunch
    io.gitgud.catpswin56.vistatasks
    io.gitgud.catpswin56.wmptoolbar

    io.gitgud.catpswin56.sidebar
    io.gitgud.catpswin56.desktopcontainment
)

foreach(plasmoid IN LISTS plasmoids)
    plasma_install_package(${plasmoid} ${plasmoid})
endforeach()

