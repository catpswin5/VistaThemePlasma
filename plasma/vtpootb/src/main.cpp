/*
    SPDX-License-Identifier: GPL-2.0-or-later
    SPDX-FileCopyrightText: 2025 WackyIdeas <wackyideas@disroot.org>
*/

#include <QtGlobal>
#include <QApplication>

#include <QString>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "app.h"
#include "version-vtpootb.h"
#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedString>

#include <thread>
#include <chrono>
#include <cstdlib>
#include "config.h"
#include "vtpootbconfig.h"

using namespace Qt::Literals::StringLiterals;

#define SHELLNAME "io.gitgud.catpswin56.desktop"

int main(int argc, char *argv[])
{

    if(const char* env_p = std::getenv("PLASMA_DEFAULT_SHELL"))
    {
        if(strcmp(env_p, SHELLNAME) != 0)
        {
            return -1;
        }
    }
    else
    {
        return -2;
    }
    KConfig ootbConfig(QStringLiteral("vistathemeplasmarc"));
    bool firstTime = ootbConfig.group(QStringLiteral("OOTB")).readEntry(QStringLiteral("wizardRun"), false);

    if(firstTime)
    {
        return 0;
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(3000));

    QApplication app(argc, argv);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }

    KLocalizedString::setApplicationDomain("vtpootb");
    QCoreApplication::setOrganizationName(u"catpswin56"_s);

    KAboutData aboutData(
        // The program name used internally.
        u"vtpootb"_s,
        // A displayable program name string.
        i18nc("@title", "vtpootb"),
        // The program version string.
        QStringLiteral(VTPOOTB_VERSION_STRING),
        // Short description of what the app does.
        i18n("Application Description"),
        // The license this code is released under.
        KAboutLicense::GPL,
        // Copyright Statement.
        i18n("(c) 2025"));
    aboutData.addAuthor(i18nc("@info:credit", "WackyIdeas"),
                        i18nc("@info:credit", "Author of the original ATPOOTB"),
                        u"wackyideas@disroot.org"_s,
                        u"https://gitgud.io/aeroshell/atp/aerothemeplasma"_s);
    aboutData.addAuthor(i18nc("@info:credit", "catpswin56"),
                        i18nc("@info:credit", "Maintainer"),
                        u"catpswin5@proton.me"_s,
                        u"https://gitgud.io/aeroshell/vtp/vistathemeplasma"_s);
    aboutData.setOrganizationDomain("gitgud.io");
    aboutData.setDesktopFileName("__VTPOOTB");
    //aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    KAboutData::setApplicationData(aboutData);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.gitgud.catpswin56.vtpootb"_s));
    QCoreApplication::setApplicationName(QStringLiteral("__VTPOOTB"));

    QQmlApplicationEngine engine;

    auto config = vtpootbConfig::self();

    qmlRegisterSingletonInstance("io.gitgud.catpswin56.vtpootb.private", 1, 0, "Config", config);
    engine.rootContext()->setContextProperty("KAUTH_ACTIONS_QML", QVariant(KAUTH_ACTIONS_QML));
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.loadFromModule("io.gitgud.catpswin56.vtpootb", u"Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
