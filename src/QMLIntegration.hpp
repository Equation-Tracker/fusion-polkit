#pragma once
#include <QObject>
#include <QString>
#include <mutex>

/**
 * CQMLIntegration — bridge between QML and the authentication agent.
 *
 * All methods called from multiple threads must be invoked via Qt's queued
 * connection mechanism (QMetaObject::invokeMethod with Qt::QueuedConnection)
 * to guarantee they execute on the Qt main thread.
 */
class CQMLIntegration : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString result   READ getResult NOTIFY resultChanged)
    Q_PROPERTY(QString message  READ getMessage NOTIFY messageChanged)
    Q_PROPERTY(QString user     READ getUser    NOTIFY userChanged)

  public:
    explicit CQMLIntegration(QObject* parent = nullptr);


    Q_INVOKABLE void setResult(const QString& str);

    Q_INVOKABLE void setError(const QString& error);
    Q_INVOKABLE void focus();
    Q_INVOKABLE void setInputBlocked(bool blocked);

    [[nodiscard]] QString getResult()  const;
    [[nodiscard]] QString getMessage() const;
    [[nodiscard]] QString getUser()    const;

  signals:
    void resultChanged();
    void messageChanged();
    void userChanged();

  private:
    QString m_result;
};