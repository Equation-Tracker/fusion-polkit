#include "QMLIntegration.hpp"
#include "core/Agent.hpp"
#include <mutex>

extern std::mutex gAgentMutex;
extern CAgent*    g_pAgent;

CQMLIntegration::CQMLIntegration(QObject* parent) : QObject(parent) {}

void CQMLIntegration::setResult(const QString& str) {
    {
        std::lock_guard<std::mutex> lock(gAgentMutex);
        m_result = str;
        if (g_pAgent)
            g_pAgent->submitResultThreadSafe(str.toStdString());
    }
    emit resultChanged();
}

void CQMLIntegration::onExit() {
    std::lock_guard<std::mutex> lock(gAgentMutex);
    if (g_pAgent)
        g_pAgent->submitResultThreadSafe("cancel");
}

QString CQMLIntegration::getMessage() const {
    if (g_pAgent)
        return g_pAgent->listenerMessage();
    return {};
}

QString CQMLIntegration::getUser() const {
    if (g_pAgent)
        return g_pAgent->listenerSelectedUser();
    return {};
}

QString CQMLIntegration::getResult() const {
    return m_result;
}

// Thread-safe UI helpers — these are Q_INVOKABLE so Agent can call them via
// QMetaObject::invokeMethod(Qt::QueuedConnection) from worker threads.
void CQMLIntegration::setError(const QString& error) {
    emit errorChanged(error);
}

void CQMLIntegration::focus() {
    emit focusRequested();
}

void CQMLIntegration::setInputBlocked(bool blocked) {
    emit inputBlockedChanged(blocked);
}