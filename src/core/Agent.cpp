// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

#define POLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE 1

#include <polkitagent/polkitagent.h>
#include <QtCore/QString>
#include <QVariant>
#include <QQmlApplicationEngine>
#include <QApplication>
#include <QQuickStyle>
#include <QQmlContext>
#include <QMetaObject>
#include <print>
#include <mutex>

#include "Agent.hpp"
#include "SecureString.hpp"
#include "../QMLIntegration.hpp"

using namespace Qt::Literals::StringLiterals;

CAgent::CAgent() {
}

CAgent::~CAgent() {
    std::lock_guard<std::mutex> lk(stateMutex);
    if (!lastAuthResult.result.empty()) {
        volatile char* p = lastAuthResult.result.data();
        for (size_t i = 0; i < lastAuthResult.result.size(); ++i)
            p[i] = 0;
    }
    lastAuthResult.result.clear();
}

bool CAgent::start() {
  sessionSubject = makeShared<PolkitQt1::UnixSessionSubject>(getpid());

  listener.registerListener(*sessionSubject, "/org/hyprland/PolicyKit1/AuthenticationAgent");

  int argc = 1;
  const char* argv[] = {[0] = "fusion-polkitagent" };
  QApplication app(argc, const_cast<char**>(argv));

  app.setApplicationName("Fusion Polkit Agent");
  QGuiApplication::setQuitOnLastWindowClosed(false);

  app.exec();
  return true;
}

void CAgent::resetAuthState() {
    std::lock_guard<std::mutex> lk(stateMutex);
    authState.qmlIntegration.reset();
    authState.qmlEngine.reset();
}

void CAgent::initAuthPrompt() {
  resetAuthState();

  if (!listenerInProgress()) {
     std::print("INTERNAL ERROR: Spawning qml prompt but session isn't in progress.\n");
     return;
  }
  std::print("Spawning QML prompt for new authentication session.\n");
  {
    std::lock_guard<std::mutex> lk(stateMutex);
    authState.qmlIntegration = std::make_unique<CQMLIntegration>();

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle("org.hyprland.style");

    authState.qmlEngine      = std::make_unique<QQmlApplicationEngine>();
    authState.qmlEngine->rootContext()->setContextProperty("hpa", authState.qmlIntegration.get());
    authState.qmlEngine->load(QUrl(u"qrc:/qt/qml/fusionpolkit/qml/main.qml"_s));

    if (authState.qmlEngine->rootObjects().isEmpty()) {
      std::print("QML LOAD FAILED\n");
    }

    QMetaObject::invokeMethod(authState.qmlIntegration.get(), "focus", Qt::QueuedConnection);
  }
}

bool CAgent::resultReady() {
    std::lock_guard<std::mutex> lk(stateMutex);
    return !lastAuthResult.used;
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
    return listener.session.inProgress;
}

QString CAgent::listenerMessage() {
    return listener.session.inProgress ? listener.session.message : "An app is requesting Authentication.";
}

QString CAgent::listenerSelectedUser() {
    if (!listener.session.inProgress)
        return "Unknown user";

    QString user = listener.session.selectedUser.toString();

    if (user.startsWith("unix-user:"))
        user.remove(0, QString("unix-user:").size());

    return user;
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