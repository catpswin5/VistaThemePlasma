/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef GROUPEDAPPLETSCONTAINER_H
#define GROUPEDAPPLETSCONTAINER_H

#include <Plasma/Applet>
#include <QQuickItem>

class GroupedAppletsContainer : public Plasma::Applet
{
    Q_OBJECT
    Q_PROPERTY(QQuickItem *internalContainmentItem READ internalContainmentItem NOTIFY internalContainmentItemChanged)

public:
    explicit GroupedAppletsContainer(QObject *parent, const KPluginMetaData &data, const QVariantList &args);
    ~GroupedAppletsContainer() override;

    void init() override;

    QQuickItem *internalContainmentItem();

protected:
    void constraintsEvent(Plasma::Applet::Constraints constraints) override;
    void ensureSystrayExists();

Q_SIGNALS:
    void internalContainmentItemChanged();

private:
    QPointer<Plasma::Containment> m_innerContainment;
    QPointer<QQuickItem> m_internalContainmentItem;
};

#endif
