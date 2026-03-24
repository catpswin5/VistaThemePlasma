/*
    SPDX-FileCopyrightText: 2021  <>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include "VistaStart.h"

#include <KApplicationTrader>
#include <KService>
#include <KSycoca>

VistaStart::VistaStart(QObject *parentObject, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Applet(parentObject, data, args)
{
    if(KWindowSystem::isPlatformX11()) {
        connect(KX11Extras::self(), SIGNAL(compositingChanged(bool)), this, SLOT(onCompositingChanged(bool)));
    }

    connect(KWindowSystem::self(), SIGNAL(showingDesktopChanged(bool)), this, SLOT(onShowingDesktopChanged(bool)));
    // FIXME: doesn't work
    connect(KSycoca::self(), &KSycoca::databaseChanged, this, &VistaStart::defaultsChanged);
}

VistaStart::~VistaStart()
{
    if(inputMaskCache) delete inputMaskCache;
}


QString VistaStart::defaultInternetEntry()
{
    KService::Ptr defaultApp = KApplicationTrader::preferredService("x-scheme-handler/http");

    if(defaultApp) return QString("applications:%1.desktop").arg(defaultApp.get()->desktopEntryName());
    else return "";
}

QString VistaStart::defaultInternetName()
{
    KService::Ptr defaultApp = KApplicationTrader::preferredService("x-scheme-handler/http");

    if(defaultApp) return defaultApp.get()->name();
    else return "";
}


QString VistaStart::defaultEmailEntry()
{
    KService::Ptr defaultApp = KApplicationTrader::preferredService("x-scheme-handler/mailto");

    if(defaultApp) return QString("applications:%1.desktop").arg(defaultApp.get()->desktopEntryName());
    else return "";
}

QString VistaStart::defaultEmailName()
{
    KService::Ptr defaultApp = KApplicationTrader::preferredService("x-scheme-handler/mailto");

    if(defaultApp) return defaultApp.get()->name();
    else return "";
}


bool VistaStart::fileExists(QUrl path)
{
    if(!path.isLocalFile()) return false;

    QFileInfo file(path.toLocalFile());
    return file.exists() && file.isFile();
}

void VistaStart::setOrb(QQuickWindow* w)
{
    orb = w;
}

void VistaStart::setMask(QString mask, bool overrideMask)
{
    QString m = mask.mid(7).toStdString().c_str();
    if(overrideMask)
    {
        if(inputMaskCache != nullptr) delete inputMaskCache;
        inputMaskCache = new QBitmap(m);
    }
    else
    {
        if(!inputMaskCache)
        {
            inputMaskCache = new QBitmap(m);
        }
    }
}


void VistaStart::setTransparentWindow()
{
    if(orb == nullptr || inputMaskCache == nullptr) return;

    bool compositingActive{true};
    if(KWindowSystem::isPlatformX11()) compositingActive = KX11Extras::compositingActive();

    if(!compositingActive) {
        orb->setMask(*inputMaskCache);
    } else {
        orb->setMask(QRegion());
    }
}

void VistaStart::setActiveWin(QQuickWindow* w)
{
    if(w == nullptr || KWindowSystem::isPlatformWayland()) return;
    KX11Extras::forceActiveWindow(w->winId());
}


void VistaStart::onCompositingChanged(bool enabled)
{
    setTransparentWindow();
}

void VistaStart::onShowingDesktopChanged(bool enabled)
{
    if(enabled && orb != nullptr)
        orb->raise();
}

K_PLUGIN_CLASS(VistaStart)

#include "VistaStart.moc"
