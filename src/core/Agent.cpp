#define POLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE 1

#include <polkitagent/polkitagent.h>
#include <print>
#include <QtCore/QString>
#include <QMetaObject>
#include <QVariant>
#include <mutex>
using namespace Qt::Literals::StringLiterals;

#include "Agent.hpp"
#include "../QMLIntegration.hpp"
#include "SecureString.hpp"

CAgent::CAgent() {
    ;
}

CAgent::~CAgent() {
    std::lock_guard<std::mutex> lk(stateMutex);
    // wipe last result
    lastAuthResult.result.clear();
}

bool CAgent::start() {
    sessionSubject = makeShared<PolkitQt1::UnixSessionSubject>(getpid());

    listener.registerListener(*sessionSubject, "/org/hyprland/PolicyKit1/AuthenticationAgent");

    int localArgc = 1;
    char localArg0[] = "hyprpolkitagent";
    char* localArgv[2] = { localArg0, nullptr };
    QApplication app(localArgc, localArgv);

    app.setApplicationName("Hyprland Polkit Agent");
    QGuiApplication::setQuitOnLastWindowClosed(false);

    app.exec();

    return true;
}

void CAgent::resetAuthState() {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (authState.authing) {
        authState.authing = false;

        if (authState.qmlEngine) {
            authState.qmlEngine->deleteLater();
            authState.qmlEngine = nullptr;
        }
        if (authState.qmlIntegration) {
            authState.qmlIntegration->deleteLater();
            authState.qmlIntegration = nullptr;
        }
    }
}

void CAgent::initAuthPrompt() {
    resetAuthState();

    if (!listener.session.inProgress) {
        std::print(stderr, "INTERNAL ERROR: Spawning qml prompt but session isn't in progress\n");
        return;
    }

    std::print("Spawning qml prompt\n");

    {
        std::lock_guard<std::mutex> lk(stateMutex);
        authState.authing = true;

        authState.qmlIntegration = new CQMLIntegration();

        if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
            QQuickStyle::setStyle("org.hyprland.style");

        authState.qmlEngine = new QQmlApplicationEngine();
        authState.qmlEngine->rootContext()->setContextProperty("hpa", authState.qmlIntegration);
        authState.qmlEngine->load(QUrl{u"qrc:/qt/qml/hpa/qml/main.qml"_s});

        // Focus via signal on the queued main thread
        QMetaObject::invokeMethod(authState.qmlIntegration, "focus", Qt::QueuedConnection);
    }
}

bool CAgent::resultReady() {
    std::lock_guard<std::mutex> lk(stateMutex);
    return !lastAuthResult.used;
}

void CAgent::submitResultThreadSafe(const std::string& result) {
    // store result briefly under lock
    {
        std::lock_guard<std::mutex> lk(stateMutex);
        lastAuthResult.used   = false;
        lastAuthResult.result = result;
    }

    // Move out and clear under lock
    std::string localStr;
    {
        std::lock_guard<std::mutex> lk(stateMutex);
        localStr = std::move(lastAuthResult.result);
        lastAuthResult.result.clear();
        lastAuthResult.used = true;
    }

    // sanitize logging: do not print sensitive data contents
    bool pass = false;
    if (localStr.rfind("auth:", 0) == 0) {
        pass = true;
    }

    std::print("Got result from qml: {}\n", pass ? "auth:**PASSWORD**" : "cancel/fail");

    if (pass) {
        const std::string pw = localStr.substr(5);
        // Use QString conversion for polkit API and wipe pw asap
        QString qpw = QString::fromUtf8(pw.c_str(), static_cast<int>(pw.size()));
        listener.submitPassword(qpw);
        qpw.fill(u'\0');
        // attempt to wipe local copy
        volatile char *p = const_cast<char*>(pw.c_str());
        for (size_t i = 0; i < pw.size(); ++i) p[i] = 0;
    } else {
        listener.cancelPending();
    }
}

// UI helpers
void CAgent::uiSetError(const QString& err) {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (!authState.qmlIntegration)
        return;
    QMetaObject::invokeMethod(authState.qmlIntegration, "setError", Qt::QueuedConnection, Q_ARG(QString, err));
}

void CAgent::uiBlockInput(bool blocked) {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (!authState.qmlIntegration)
        return;
    QMetaObject::invokeMethod(authState.qmlIntegration, "setInputBlocked", Qt::QueuedConnection, Q_ARG(bool, blocked));
}

void CAgent::uiFocusField() {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (!authState.qmlIntegration)
        return;
    QMetaObject::invokeMethod(authState.qmlIntegration, "focus", Qt::QueuedConnection);
}

// listener accessors
bool CAgent::listenerInProgress() {
    return listener.session.inProgress;
}

QString CAgent::listenerMessage() {
    return listener.session.inProgress ? listener.session.message : QString{};
}

QString CAgent::listenerSelectedUser() {
    return listener.session.inProgress ? listener.session.selectedUser.toString() : QString{};
}
