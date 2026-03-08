#ifndef POSITIONMANAGER_H
#define POSITIONMANAGER_H

#include <QObject>
#include <QQuickItem>
#include <QPointer>
#include <QQmlEngine>
#include <QJsonArray>
#include <QJsonObject>

class PositionManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickItem *container READ container WRITE setContainer NOTIFY containerChanged)
    Q_PROPERTY(bool refreshAutomatically READ refreshAutomatically WRITE setRefreshAutomatically NOTIFY refreshAutomaticallyChanged)
    Q_PROPERTY(QJsonArray positions READ positions WRITE setPositions NOTIFY refreshed)

public:
    explicit PositionManager(QObject *parent = nullptr);
    ~PositionManager();

    QQuickItem *container();
    void setContainer(QQuickItem *container);

    bool refreshAutomatically();
    void setRefreshAutomatically(bool refreshAutomatically);

    QJsonArray positions();
    void setPositions(QJsonArray positions);
    Q_INVOKABLE QJsonObject getPositionObject(QQuickItem *item);

Q_SIGNALS:
    void containerChanged();
    void refreshAutomaticallyChanged();

    void aboutToRefresh();
    void refreshed();

public Q_SLOTS:
    void ensurePositions();
    void refresh();

private Q_SLOTS:
    void checkRefresh();

private:
    void setupConnections();
    void unsetupConnections();

    QPointer<QQuickItem> m_container;

    bool m_refreshAutomatically;

    QJsonArray m_positions;
};

#endif // POSITIONMANAGER_H
