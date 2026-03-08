#include "positionmanager.h"

#include <QJsonValue>

PositionManager::PositionManager(QObject *parent)
    : QObject{parent}
    , m_refreshAutomatically{false}
{}

PositionManager::~PositionManager()
{}


QQuickItem *PositionManager::container()
{ return m_container.data(); }

void PositionManager::setContainer(QQuickItem *container)
{
    unsetupConnections();
    m_container = container;
    setupConnections();

    Q_EMIT containerChanged();
}


bool PositionManager::refreshAutomatically()
{ return m_refreshAutomatically; }

void PositionManager::setRefreshAutomatically(bool refreshAutomatically)
{
    m_refreshAutomatically = refreshAutomatically;
    Q_EMIT refreshAutomaticallyChanged();
}


QJsonArray PositionManager::positions()
{ return m_positions; }

void PositionManager::setPositions(QJsonArray positions)
{
    m_positions = positions;
    Q_EMIT refreshed();
}

QJsonObject PositionManager::getPositionObject(QQuickItem *item)
{
    if(!m_container) return {};

    int index = item->property("posIdx").toInt();
    QString id = item->property("posId").toString();

    auto it = std::find_if(m_positions.begin(), m_positions.end(), [&](const QJsonValueRef &objRef) {
        int objIdx = objRef.toObject().value("index").toInt();
        QString objId = objRef.toObject().value("id").toString();
        return objIdx == index && objId == id;
    });

    if(it != m_positions.end()) return (*it).toObject();

    return {};
}


void PositionManager::ensurePositions()
{
    if(!m_container) return;

    // disable temporarily
    bool prevVal = m_refreshAutomatically;
    m_refreshAutomatically = false;

    for(QQuickItem *item : m_container->childItems()) {
        QJsonObject obj = getPositionObject(item);

        if(obj.isEmpty()) continue;

        item->setX(obj.value("x").toDouble());
        item->setY(obj.value("y").toDouble());

        item->setWidth(obj.value("width").toDouble());
        item->setHeight(obj.value("height").toDouble());
    }

    m_refreshAutomatically = prevVal;
}

void PositionManager::refresh()
{
    if(!m_container) return;

    Q_EMIT aboutToRefresh();

    m_positions = QJsonArray{};
    for(QQuickItem *item : m_container->childItems()) {
        int index = item->property("posIdx").toInt();
        QString id = item->property("posId").toString();

        // this item doesn't want to appear in the list
        if(index == -1) continue;

        QJsonObject obj{};

        obj.insert("index", {index});
        obj.insert("id", {id});

        obj.insert("x", {item->x()});
        obj.insert("y", {item->y()});

        obj.insert("width", {item->width()});
        obj.insert("height", {item->height()});

        m_positions.append({obj});
    }

    Q_EMIT refreshed();
}


void PositionManager::checkRefresh()
{ if(m_refreshAutomatically) refresh(); }


void PositionManager::setupConnections()
{
    if(!m_container) return;

    connect(m_container.data(), &QQuickItem::visibleChildrenChanged, this, &PositionManager::checkRefresh);
    connect(m_container.data(), &QQuickItem::childrenRectChanged, this, &PositionManager::checkRefresh);

    for(QQuickItem *item : m_container->childItems()) {
        if(item->property("posIdx").toInt() == -1) continue;

        connect(item, &QQuickItem::xChanged, this, &PositionManager::checkRefresh);
        connect(item, &QQuickItem::yChanged, this, &PositionManager::checkRefresh);

        connect(item, &QQuickItem::widthChanged, this, &PositionManager::checkRefresh);
        connect(item, &QQuickItem::heightChanged, this, &PositionManager::checkRefresh);
    }
}

void PositionManager::unsetupConnections()
{
    if(!m_container) return;

    disconnect(m_container.data(), &QQuickItem::visibleChildrenChanged, this, &PositionManager::checkRefresh);
    disconnect(m_container.data(), &QQuickItem::childrenRectChanged, this, &PositionManager::checkRefresh);

    for(QQuickItem *item : m_container->childItems()) {
        if(item->property("posIdx").toInt() == -1) continue;

        disconnect(item, &QQuickItem::xChanged, this, &PositionManager::checkRefresh);
        disconnect(item, &QQuickItem::yChanged, this, &PositionManager::checkRefresh);

        disconnect(item, &QQuickItem::widthChanged, this, &PositionManager::checkRefresh);
        disconnect(item, &QQuickItem::heightChanged, this, &PositionManager::checkRefresh);
    }
}
