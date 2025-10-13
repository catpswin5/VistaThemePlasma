/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2025 catpswin56 <>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef DESKTOPCONTAINMENT_H
#define DESKTOPCONTAINMENT_H

#include <QCursor>

#include <Plasma/Containment>

class QQuickItem;

class DesktopContainment : public Plasma::Containment
{
    Q_OBJECT
public:
    explicit DesktopContainment(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    // Creates an applet
    Q_INVOKABLE void newTask(const QString &task, const int &x, const int &y);

    // cleans all instances of a given applet
    Q_INVOKABLE void cleanupTask(const QString &task);

    /**
     * Given an AppletInterface pointer, shows a proper context menu for it
     */
    Q_INVOKABLE void showPlasmoidMenu(QQuickItem *appletInterface, int x, int y);

Q_SIGNALS:
    void taskCreated(Plasma::Applet *applet, int x, int y);
};

#endif
