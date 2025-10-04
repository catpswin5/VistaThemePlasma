/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2025 catpswin56 <>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef SIDEBAR_H
#define SIDEBAR_H

#include <QCursor>

#include <Plasma/Containment>

class QQuickItem;

class Sidebar : public Plasma::Containment
{
    Q_OBJECT
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

    // Configure the sidebar window
    Q_INVOKABLE void configureWindow(QWindow *window, const QRectF &rect, const bool &reserveSpace, const bool &right);

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

    /**
     * Reparent the item "before" with the same parent as the item "after",
     * then restack it before it, using QQuickITem::stackBefore.
     * used to quickly reorder icons in the systray (or hidden popup)
     * @see QQuickITem::stackBefore
     */
    Q_INVOKABLE void reorderItemBefore(QQuickItem *before, QQuickItem *after);

    /**
     * Reparent the item "after" with the same parent as the item "before",
     * then restack it after it, using QQuickITem::stackAfter.
     * used to quickly reorder icons in the systray (or hidden popup)
     * @see QQuickITem::stackAfter
     */
    Q_INVOKABLE void reorderItemAfter(QQuickItem *after, QQuickItem *before);

private:
    bool m_docked = false;
    bool m_X11_underlap = false;
};

#endif
