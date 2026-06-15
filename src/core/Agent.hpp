#pragma once

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QScreen>
#include <memory>
#include <mutex>

#include "PolkitListener.hpp"
#include <polkitqt1-subject.h>

#include <hyprutils/memory/WeakPtr.hpp>
using namespace Hyprutils::Memory;
#define SP CSharedPointer
#define WP CWeakPointer

class CQMLIntegration;

class CAgent {
  public:
    CAgent();
    ~CAgent();

    void submitResultThreadSafe(std::string result);
    void resetAuthState();
    bool start();
    void initAuthPrompt();

  private:

    struct {
        bool authing = false;
        std::unique_ptr<QQmlApplicationEngine> qmlEngine;
        std::unique_ptr<CQMLIntegration> qmlIntegration;
    } authState;

    struct {
        std::string result;
        bool        used = true;
    } lastAuthResult;

    CPolkitListener                   listener;
    SP<PolkitQt1::UnixSessionSubject> sessionSubject;

    bool                              resultReady();

    friend class CQMLIntegration;
    friend class CPolkitListener;
};

inline std::unique_ptr<CAgent> g_pAgent;
inline std::mutex gAgentMutex;