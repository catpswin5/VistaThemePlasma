/*
 *   SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "groupedappletscontainer.h"
#include "debug.h"

#include <QDebug>

#include <KActionCollection>
#include <Plasma/Corona>
#include <PlasmaQuick/AppletQuickItem>
#include <QAction>

GroupedAppletsContainer::GroupedAppletsContainer(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : Plasma::Applet(parent, data, args)
{
}

GroupedAppletsContainer::~GroupedAppletsContainer()
{
    if (destroyed()) {
        m_innerContainment->destroy();
    }
}

void GroupedAppletsContainer::init()
{
    Applet::init();

    // in the first creation we immediately create the systray: so it's accessible during desktop scripting
    uint id = config().readEntry("ContainmentId", 0);

    if (id == 0) {
        ensureSystrayExists();
    }
}

void GroupedAppletsContainer::ensureSystrayExists()
{
    if (m_innerContainment) {
        return;
    }

    Plasma::Containment *cont = containment();
    if (!cont) {
        return;
    }

    Plasma::Corona *c = cont->corona();
    if (!c) {
        return;
    }

    uint id = config().readEntry("ContainmentId", 0);
    if (id > 0) {
        const auto containments = c->containments();
        for (Plasma::Containment *candidate : containments) {
            if (candidate->id() == id) {
                m_innerContainment = candidate;
                break;
            }
        }
        qCDebug(GROUPING_DEBUG) << "Containment id" << id << "that used to be a grouped containment that was deleted";
        // id = 0;
    }

    if (!m_innerContainment) {
        m_innerContainment = c->createContainment(QStringLiteral("io.gitgud.catpswin56.private.sidebar"), //
                                                  QVariantList() << QStringLiteral("org.kde.plasma:force-create"));
        config().writeEntry("ContainmentId", m_innerContainment->id());
    }

    if (!m_innerContainment) {
        return;
    }

    m_innerContainment->setParent(this);
    connect(containment(), &Plasma::Containment::screenChanged, m_innerContainment.data(), &Plasma::Containment::reactToScreenChange);
    m_innerContainment->setFormFactor(formFactor());
    m_innerContainment->setLocation(location());

    m_internalContainmentItem = PlasmaQuick::AppletQuickItem::itemForApplet(m_innerContainment);
    Q_EMIT internalContainmentItemChanged();

    setInternalAction(QStringLiteral("configure"), m_innerContainment->internalAction(QStringLiteral("configure")));
    connect(m_innerContainment.data(), &Plasma::Containment::configureRequested, this, [this](Plasma::Applet *applet) {
        Q_EMIT containment()->configureRequested(applet);
    });

    if (m_internalContainmentItem) {
        // don't let internal systray manage context menus
        m_internalContainmentItem->setAcceptedMouseButtons(Qt::NoButton);
    }

    // replace internal remove action with ours
    m_innerContainment->setInternalAction(QStringLiteral("remove"), internalAction(QStringLiteral("remove")));
}

void GroupedAppletsContainer::constraintsEvent(Plasma::Applet::Constraints constraints)
{
    if (constraints & Plasma::Applet::LocationConstraint) {
        if (m_innerContainment) {
            m_innerContainment->setLocation(location());
        }
    }
    if (constraints & Plasma::Applet::FormFactorConstraint) {
        if (m_innerContainment) {
            m_innerContainment->setFormFactor(formFactor());
        }
    }

    if (constraints & Plasma::Applet::UiReadyConstraint) {
        ensureSystrayExists();
    }
}

QQuickItem *GroupedAppletsContainer::internalContainmentItem()
{
    return m_internalContainmentItem;
}

K_PLUGIN_CLASS(GroupedAppletsContainer)

#include "groupedappletscontainer.moc"
