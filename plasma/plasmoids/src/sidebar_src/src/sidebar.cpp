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

QQuickWindow *Sidebar::window() const
{
    return m_window;
}

void Sidebar::setWindow(QQuickWindow *window)
{
    if (m_window) {
        disconnect(m_window, nullptr, this, nullptr);

        m_window = nullptr;
        m_layerWindow = nullptr;
    }

    m_window = window;
    m_layerWindow = LayerShellQt::Window::get(window);

    connect(m_window, &QQuickWindow::visibleChanged, this, &Sidebar::configureWindow);
    connect(m_window, &QQuickWindow::xChanged,       this, &Sidebar::configureWindow);
    connect(m_window, &QQuickWindow::yChanged,       this, &Sidebar::configureWindow);
    connect(m_window, &QQuickWindow::widthChanged,   this, &Sidebar::configureWindow);
    connect(m_window, &QQuickWindow::heightChanged,  this, &Sidebar::configureWindow);

    Q_EMIT windowChanged();
}

bool Sidebar::reserveScreenArea() const
{
    return m_reserveScreenArea;
}

void Sidebar::setReserveScreenArea(bool reserveScreenArea)
{
    m_reserveScreenArea = reserveScreenArea;
    Q_EMIT reserveScreenAreaChanged();

    configureWindow();
}

bool Sidebar::positionRight() const
{
    return m_positionRight;
}

void Sidebar::setPositionRight(bool positionRight)
{
    m_positionRight = positionRight;
    Q_EMIT positionRightChanged();

    configureWindow();
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

void Sidebar::configureWindow()
{
    if (!m_window) {
        return;
    }

    if (m_reserveScreenArea) {
        KWindowEffects::enableBlurBehind(m_window, true, QRegion());
    } else if (!m_reserveScreenArea && m_docked) {
        KWindowEffects::enableBlurBehind(m_window, false, QRegion());
    }

    disconnect(m_window, &QQuickWindow::visibleChanged, this, &Sidebar::configureWindow);

    bool previousVal = m_window->isVisible();
    m_window->setVisible(false);

    QRect rect = m_window->geometry();

    if (KWindowSystem::isPlatformX11()) {
        WId windowId = m_window->winId();

        if (!m_docked) {
            KX11Extras::setType(windowId, NET::Normal);
        }

        NET::States states;
        states |= NET::SkipTaskbar;
        states |= NET::SkipPager;
        states |= NET::SkipSwitcher;

        KX11Extras::setOnAllDesktops(windowId, true);
        KX11Extras::setState(windowId, states);

        if (!m_reserveScreenArea && m_docked) {
            m_window->setX(m_window->screen()->geometry().width() - rect.width());
            m_window->setY(0);
            m_window->setHeight(m_window->screen()->availableGeometry().height());

            KX11Extras::setExtendedStrut(windowId,
                                         0, 0, 0,
                                         0, 0, 0,
                                         0, 0, 0,
                                         0, 0, 0);
            m_docked = false;
            KX11Extras::setType(windowId, NET::Normal);
        }

        if (m_reserveScreenArea) {
            KX11Extras::setType(windowId, NET::Dock);

            if (!m_positionRight) {
                KX11Extras::setExtendedStrut(windowId,
                                             rect.width(), rect.y(), rect.y() + rect.height(),
                                             0, 0, 0,
                                             0, 0, 0,
                                             0, 0, 0);

            } else {
                KX11Extras::setExtendedStrut(windowId,
                                             0, 0, 0,
                                             rect.width(), rect.y(), rect.y() + rect.height(),
                                             0, 0, 0,
                                             0, 0, 0);

            }

            m_docked = true;
        }
    } else {
        if (m_layerWindow) {
            LayerShellQt::Window::Anchors anchors;
            anchors.setFlag(LayerShellQt::Window::AnchorTop);
            anchors.setFlag(LayerShellQt::Window::AnchorBottom);

            if (m_positionRight) {
                anchors.setFlag(LayerShellQt::Window::AnchorRight);
            } else {
                anchors.setFlag(LayerShellQt::Window::AnchorLeft);
            }

            m_layerWindow->setAnchors(anchors);
            m_layerWindow->setLayer(LayerShellQt::Window::LayerBottom);

            if (!m_reserveScreenArea && m_docked) {
                m_layerWindow->setExclusiveZone(0);
                m_docked = false;
            }

            if (m_reserveScreenArea) {
                m_layerWindow->setExclusiveZone(rect.width());
                m_docked = true;
            }
        }
    }

    m_window->setVisible(previousVal);

    connect(m_window, &QQuickWindow::visibleChanged, this, &Sidebar::configureWindow);
}

K_PLUGIN_CLASS(Sidebar)

#include "sidebar.moc"
