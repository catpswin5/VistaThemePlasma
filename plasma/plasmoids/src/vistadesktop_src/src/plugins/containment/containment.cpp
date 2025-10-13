/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "containment.h"

#include <QDebug>
#include <QMenu>
#include <QQuickItem>
#include <QQuickWindow>
#include <QScreen>
#include <QStandardItemModel>

#include <KActionCollection> // Applet::actions

DesktopContainment::DesktopContainment(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Containment(parent, data, args)
{
    QObject::connect(this, &Plasma::Containment::appletAdded, this, [](){
        qDebug() << "vistadesktop: applet added";
    });
}

void DesktopContainment::newTask(const QString &task, const int &x = 0, const int &y = 0)
{
    Plasma::Applet *createdApplet = createApplet(task, QVariantList());
    if(createdApplet) Q_EMIT taskCreated(createdApplet, x, y);
}

void DesktopContainment::cleanupTask(const QString &task)
{
    const auto appletList = applets();
    for (Plasma::Applet *applet : appletList) {
        if (!applet->pluginMetaData().isValid() || task == applet->pluginMetaData().pluginId()) {
            applet->destroy();
        }
    }
}

void DesktopContainment::showPlasmoidMenu(QQuickItem *appletInterface, int x, int y)
{
    if (!appletInterface) {
        return;
    }

    Plasma::Applet *applet = appletInterface->property("_plasma_applet").value<Plasma::Applet *>();

    QPointF pos = appletInterface->mapToScene(QPointF(x, y));

    if (appletInterface->window() && appletInterface->window()->screen()) {
        pos = appletInterface->window()->mapToGlobal(pos.toPoint());
    } else {
        pos = QPoint();
    }

    QMenu *desktopMenu = new QMenu;
    connect(this, &QObject::destroyed, desktopMenu, &QMenu::close);
    desktopMenu->setAttribute(Qt::WA_DeleteOnClose);

    Q_EMIT applet->contextualActionsAboutToShow();
    const QList<QAction *> actions = applet->contextualActions();
    for (QAction *action : actions) {
        if (action) {
            desktopMenu->addAction(action);
        }
    }

    if (desktopMenu->isEmpty()) {
        delete desktopMenu;
        return;
    }

    desktopMenu->adjustSize();

    if (QScreen *screen = appletInterface->window()->screen()) {
        const QRect geo = screen->availableGeometry();

        pos =
            QPoint(qBound(geo.left(), (int)pos.x(), geo.right() - desktopMenu->width()), qBound(geo.top(), (int)pos.y(), geo.bottom() - desktopMenu->height()));
    }

    desktopMenu->popup(pos.toPoint());
}

K_PLUGIN_CLASS(DesktopContainment)

#include "containment.moc"
