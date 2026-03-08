/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2026 catpswin56 <catpswin5@proton.me>
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

    Q_PROPERTY(QObject *layout READ layout WRITE setLayout NOTIFY layoutChanged)

public:
    explicit DesktopContainment(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    // Creates an applet
    Q_INVOKABLE void newTask(const QString &task);

    // cleans all instances of a given applet
    Q_INVOKABLE void cleanupTask(const QString &task);

    QObject *layout();
    void setLayout(QObject *layout);

    /**
     * Given an AppletInterface pointer, shows a proper context menu for it
     */
    Q_INVOKABLE void showPlasmoidMenu(QQuickItem *appletInterface, int x, int y);

Q_SIGNALS:
    void taskCreated(Plasma::Applet *applet, int x, int y);
    void appletDeletion(Plasma::Applet *applet);

    void layoutChanged(QObject *layout);

    // emitted after the layout changes and all applets are added
    void appletsAdded();

private:
    QObject *m_layout = nullptr;
};

#endif
