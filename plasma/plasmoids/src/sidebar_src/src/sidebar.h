/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2026 catpswin56 <catpswin5@proton.me>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef SIDEBAR_H
#define SIDEBAR_H

#include <QObject>
#include <QCursor>
#include <QQuickWindow>

#include <Plasma/Containment>

namespace LayerShellQt
{
class Window;
}

class QQuickItem;

class Sidebar : public Plasma::Containment
{
    Q_OBJECT

    Q_PROPERTY(QQuickWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(bool reserveScreenArea READ reserveScreenArea WRITE setReserveScreenArea NOTIFY reserveScreenAreaChanged)
    Q_PROPERTY(bool positionRight READ positionRight WRITE setPositionRight NOTIFY positionRightChanged)
public:
    explicit Sidebar(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    // Creates an applet
    Q_INVOKABLE void newTask(const QString &task);

    // cleans all instances of a given applet
    Q_INVOKABLE void cleanupTask(const QString &task);

    /**
     * Given an AppletInterface pointer, shows a proper context menu for it
     */
    Q_INVOKABLE void showPlasmoidMenu(QQuickItem *appletInterface, int x, int y);

    QQuickWindow *window() const;
    void setWindow(QQuickWindow *window);

    bool reserveScreenArea() const;
    void setReserveScreenArea(bool reserveScreenArea);

    bool positionRight() const;
    void setPositionRight(bool positionRight);

    /**
     * Returns the cursor position. This only exists because there's no way
     * of getting the cursor position through QML.
     */
    Q_INVOKABLE QPoint cursorPosition();

    /**
     * Find out global coordinates for a popup given local MouseArea
     * coordinates
     */
    Q_INVOKABLE QPointF popupPosition(QQuickItem *visualParent, int x, int y);

public Q_SLOTS:
    Q_INVOKABLE void configureWindow();

Q_SIGNALS:
    void windowChanged();
    void reserveScreenAreaChanged();
    void positionRightChanged();

private:
    bool m_docked = false;
    bool m_X11_underlap = false;

    QQuickWindow *m_window = nullptr;
    bool m_reserveScreenArea = false;
    bool m_positionRight = false;

    LayerShellQt::Window *m_layerWindow = nullptr;
};

#endif
