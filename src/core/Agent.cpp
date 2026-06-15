#include "Agent.hpp"
#include "SecureString.hpp"
#include "../QMLIntegration.hpp"
#include <QQmlEngine>
#include <QMetaObject>
#include <print>
#include <mutex>

std::mutex gAgentMutex;

CAgent::CAgent() {
    g_pAgent = this;
}

CAgent::~CAgent() {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (!lastAuthResult.result.empty()) {
        volatile char* p = lastAuthResult.result.data();
        for (size_t i = 0; i < lastAuthResult.result.size(); ++i)
            p[i] = 0;
    }
    lastAuthResult.result.clear();

    g_pAgent = nullptr;
}

void CAgent::resetAuthState() {
    std::lock_guard<std::mutex> lk(stateMutex);
    authState.qmlIntegration.reset();
    authState.qmlEngine.reset();
}

void CAgent::initAuthPrompt() {
    std::lock_guard<std::mutex> lk(stateMutex);
    authState.qmlEngine      = std::make_unique<QQmlEngine>();
    authState.qmlIntegration = std::make_unique<CQMLIntegration>();
}

void CAgent::submitResultThreadSafe(const std::string& result) {
    std::string localStr;
    {
        std::lock_guard<std::mutex> lk(stateMutex);
        lastAuthResult.used   = false;
        localStr              = result;
        lastAuthResult.result.clear();
        lastAuthResult.used   = true;
    }

    const bool pass = (localStr.rfind("auth:", 0) == 0);
    std::print("Got result from qml: {}\n", pass ? "auth:**PASSWORD**" : "cancel/fail");

    if (pass) {
        SecureString pw(localStr.data() + 5, localStr.size() - 5);

        {
            volatile char* p = localStr.data();
            for (size_t i = 0; i < localStr.size(); ++i)
                p[i] = 0;
        }
        localStr.clear();

        QString qpw = QString::fromUtf8(pw.data(), static_cast<int>(pw.size()));
        listener.submitPassword(qpw);

        qpw.fill(u'\0');
    } else {
        {
            volatile char* p = localStr.data();
            for (size_t i = 0; i < localStr.size(); ++i)
                p[i] = 0;
        }
        localStr.clear();

        listener.cancelPending();
    }

    uiBlockInput(true);
}

bool CAgent::listenerInProgress() {
    std::lock_guard<std::mutex> lk(stateMutex);
    return listener.session.inProgress;
}

QString CAgent::listenerMessage() {
    std::lock_guard<std::mutex> lk(stateMutex);
    return listener.session.inProgress ? listener.session.message : QString{};
}

QString CAgent::listenerSelectedUser() {
    std::lock_guard<std::mutex> lk(stateMutex);
    return listener.session.inProgress ? listener.session.selectedUser.toString() : QString{};
}

void CAgent::uiSetError(const QString& msg) {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (authState.qmlIntegration)
        QMetaObject::invokeMethod(authState.qmlIntegration.get(), "setError",
                                  Qt::QueuedConnection, Q_ARG(QString, msg));
}

void CAgent::uiBlockInput(bool blocked) {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (authState.qmlIntegration)
        QMetaObject::invokeMethod(authState.qmlIntegration.get(), "setInputBlocked",
                                  Qt::QueuedConnection, Q_ARG(bool, blocked));
}

void CAgent::uiFocus() {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (authState.qmlIntegration)
        QMetaObject::invokeMethod(authState.qmlIntegration.get(), "focus",
                                  Qt::QueuedConnection);
}