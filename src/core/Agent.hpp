// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

#pragma once
#include "PolkitListener.hpp"
#include <polkitqt1-subject.h>
#include "SecureString.hpp"
#include <memory>
#include <mutex>
#include <QQmlApplicationEngine>
#include <QString>

#include <hyprutils/memory/WeakPtr.hpp>
using namespace Hyprutils::Memory;

class CQMLIntegration;
class QQmlEngine;

struct SAuthResult {
    std::string result;
    bool        used = false;
};

struct SAuthState {
    std::unique_ptr<QQmlApplicationEngine>        qmlEngine;
    std::unique_ptr<CQMLIntegration>   qmlIntegration;
};

class CAgent {
  public:
    CAgent();
    ~CAgent();

    void resetAuthState();
    void initAuthPrompt();
    bool start();
    void submitResultThreadSafe(const std::string& result);

    bool    listenerInProgress();
    QString listenerMessage();
    QString listenerSelectedUser();

    void uiSetError(const QString& msg);
    void uiBlockInput(bool blocked);
    void uiFocus();

    bool resultReady();
    SAuthState      authState;
    CPolkitListener listener;
    CSharedPointer<PolkitQt1::UnixSessionSubject> sessionSubject;

    // stateMutex: protects authState and lastAuthResult
    std::mutex stateMutex;

    friend class CQMLIntegration;
    friend class CPolkitListener;

  private:
    SAuthResult lastAuthResult;
};

// Global pointer — defined in Agent.cpp, extern'd by listener/QML integration.
inline std::mutex gAgentMutex;
inline std::unique_ptr<CAgent> g_pAgent;