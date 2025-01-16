#include "executedlg.h"

#include <QApplication>
#include <QGuiApplication>
#include <QScreen>
#include <QCoreApplication>

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationName("catpswin56");
    QCoreApplication::setApplicationName("execbin");

    QApplication a(argc, argv);
    ExecuteDlg w;
    w.show();
    auto screct = QGuiApplication::primaryScreen()->availableGeometry();
    int paddingX = 18;
    int paddingY = paddingX/2;
    w.move(screct.x() + paddingX, screct.y() + screct.height() - w.height() - paddingY);
    return a.exec();
}
