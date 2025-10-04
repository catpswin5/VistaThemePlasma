/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "sidebar.h"

#include <QDebug>
#include <QMenu>
#include <QQuickItem>
#include <QQuickWindow>
#include <QScreen>
#include <QStandardItemModel>

#include <PlasmaQuick/PlasmaShellWaylandIntegration>
#include <LayerShellQt/Window>

#include <KX11Extras>
#include <KWindowSystem>
#include <KF6/KWindowSystem/kwindoweffects.h>
#include <KActionCollection> // Applet::actions

Sidebar::Sidebar(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Containment(parent, data, args)
{
    setHasConfigurationInterface(true);
}

void Sidebar::newTask(const QString &task)
{
    createApplet(task, QVariantList());
}

void Sidebar::cleanupTask(const QString &task)
{
    const auto appletList = applets();
    for (Plasma::Applet *applet : appletList) {
        if (!applet->pluginMetaData().isValid() || task == applet->pluginMetaData().pluginId()) {
            applet->destroy();
        }
    }
}

void Sidebar::showPlasmoidMenu(QQuickItem *appletInterface, int x, int y)
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

void Sidebar::configureWindow(QWindow *window, const QRectF &rect, const bool &reserveSpace, const bool &right)
{
    if(reserveSpace) KWindowEffects::enableBlurBehind(window, true, QRegion(0,0, 0, 0));
    else if(!reserveSpace && m_docked) KWindowEffects::enableBlurBehind(window, false, QRegion(0,0, 0, 0));

    if(KWindowSystem::isPlatformX11())
    {
        WId windowId = window->winId();

        if(!m_docked) KX11Extras::setType(windowId, NET::Normal);

        NET::States states;
        states |= NET::SkipTaskbar;
        states |= NET::SkipPager;
        states |= NET::SkipSwitcher;
        // states |= NET::KeepBelow;

        KX11Extras::setOnAllDesktops(windowId, true);
        KX11Extras::setState(windowId, states);

        if(!reserveSpace && m_docked) {
            KX11Extras::setExtendedStrut(windowId,
                                         0, 0, 0,
                                         0, 0, 0,
                                         0, 0, 0,
                                         0, 0, 0);
            m_docked = false;
            KX11Extras::setType(windowId, NET::Normal);
        }
        if(reserveSpace) {
            KX11Extras::setType(windowId, NET::Dock);

            if(!right) {
                KX11Extras::setExtendedStrut(windowId,
                                             rect.width(), rect.y(), rect.y() + rect.height(),
                                             0, 0, 0,
                                             0, 0, 0,
                                             0, 0, 0);

            }
            else {
                KX11Extras::setExtendedStrut(windowId,
                                             0, 0, 0,
                                             rect.width(), rect.y(), rect.y() + rect.height(),
                                             0, 0, 0,
                                             0, 0, 0);

            }

            m_docked = true;
        }
    }
    else
    {
        // why is docking a window this complicated under Wayland bro
        LayerShellQt::Window *layerWindow = LayerShellQt::Window::get(window);
        PlasmaShellWaylandIntegration *shellWindow = PlasmaShellWaylandIntegration::get(window);

        if(layerWindow) {
            LayerShellQt::Window::Anchors anchors;
            anchors.setFlag(LayerShellQt::Window::AnchorTop);
            anchors.setFlag(LayerShellQt::Window::AnchorBottom);

            if(right) anchors.setFlag(LayerShellQt::Window::AnchorRight);
            else anchors.setFlag(LayerShellQt::Window::AnchorLeft);

            layerWindow->setAnchors(anchors);
            layerWindow->setLayer(LayerShellQt::Window::LayerBottom);

            shellWindow->setPanelBehavior(QtWayland::org_kde_plasma_surface::panel_behavior_always_visible);

            if(!reserveSpace && m_docked) {
                layerWindow->setExclusiveZone(0);

                shellWindow->setRole(QtWayland::org_kde_plasma_surface::role_normal);

                m_docked = false;
            }
            if(reserveSpace) {
                shellWindow->setRole(QtWayland::org_kde_plasma_surface::role_panel);

                layerWindow->setExclusiveZone(rect.width());

                m_docked = true;
            }
        }
    }
}

QPoint Sidebar::cursorPosition()
{
    return QCursor::pos();
}

QPointF Sidebar::popupPosition(QQuickItem *visualParent, int x, int y)
{
    if (!visualParent) {
        return QPointF(0, 0);
    }

    QPointF pos = visualParent->mapToScene(QPointF(x, y));

    if (visualParent->window() && visualParent->window()->screen()) {
        pos = visualParent->window()->mapToGlobal(pos.toPoint());
    } else {
        return QPoint();
    }
    return pos;
}

void Sidebar::reorderItemBefore(QQuickItem *before, QQuickItem *after)
{
    if (!before || !after) {
        return;
    }

    before->setVisible(false);
    before->setParentItem(after->parentItem());
    before->stackBefore(after);
    before->setVisible(true);
}

void Sidebar::reorderItemAfter(QQuickItem *after, QQuickItem *before)
{
    if (!before || !after) {
        return;
    }

    after->setVisible(false);
    after->setParentItem(before->parentItem());
    after->stackAfter(before);
    after->setVisible(true);
}

K_PLUGIN_CLASS(Sidebar)

#include "sidebar.moc"
