// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

#include "QMLIntegration.hpp"
#include "core/Agent.hpp"
#include <mutex>

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
    emit setErrorString(error);
}

void CQMLIntegration::focus() {
    emit focusField();
}

void CQMLIntegration::setInputBlocked(bool blocked) {
    emit blockInput(blocked);
}