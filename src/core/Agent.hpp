#pragma once

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QScreen>
#include <mutex>

#include "PolkitListener.hpp"
#include <polkitqt1-subject.h>

#include "SecureString.hpp"

#include <hyprutils/memory/WeakPtr.hpp>
using namespace Hyprutils::Memory;
#define SP CSharedPointer
#define WP CWeakPointer

class CQMLIntegration;

class CAgent {
  public:
    CAgent();
    ~CAgent();

    void submitResultThreadSafe(const std::string& result);
    void resetAuthState();
    bool start();
    void initAuthPrompt();

    // UI helpers (thread-safe)
    void uiSetError(const QString& err);
    void uiBlockInput(bool blocked);
    void uiFocusField();

    // listener accessors
    bool listenerInProgress();
    QString listenerMessage();
    QString listenerSelectedUser();

  private:
    struct {
        bool                   authing        = false;
        QQmlApplicationEngine* qmlEngine      = nullptr;
        CQMLIntegration*       qmlIntegration = nullptr;
    } authState;

    struct {
        std::string result;
        bool        used = true;
    } lastAuthResult;

    CPolkitListener                   listener;
    SP<PolkitQt1::UnixSessionSubject> sessionSubject;

    bool                              resultReady();

    std::mutex                        stateMutex;

    friend class CQMLIntegration;
    friend class CPolkitListener;
};

inline std::unique_ptr<CAgent> g_pAgent;
