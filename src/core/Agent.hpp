#pragma once
#include "PolkitListener.hpp"
#include "SecureString.hpp"
#include <memory>
#include <mutex>
#include <QString>

class CQMLIntegration;
class QQmlEngine;

struct SAuthResult {
    std::string result;
    bool        used = false;
};

struct SAuthState {
    std::unique_ptr<QQmlEngine>        qmlEngine;
    std::unique_ptr<CQMLIntegration>   qmlIntegration;
};

class CAgent {
  public:
    CAgent();
    ~CAgent();

    void resetAuthState();
    void initAuthPrompt();

    /**
     * Called from any thread to submit a result (password or "cancel").
     * Internally acquires stateMutex; safe to call concurrently.
     */
    void submitResultThreadSafe(const std::string& result);

    // ------------------------------------------------------------------ //
    //  Thread-safe listener accessors                                      //
    //  FIX (Major): The original accessors read listener.session without   //
    //  holding any mutex, creating data races with Polkit callbacks.        //
    //  All three now hold stateMutex for the duration of the read.          //
    // ------------------------------------------------------------------ //

    /** Thread-safe: returns true if a Polkit auth session is in progress. */
    bool    listenerInProgress();

    /** Thread-safe: returns the current auth prompt message, or empty. */
    QString listenerMessage();

    /** Thread-safe: returns the selected user for the current session, or empty. */
    QString listenerSelectedUser();

    // ------------------------------------------------------------------ //
    //  Thread-safe UI helpers                                              //
    //  Agent routes all UI updates through these so every call site uses   //
    //  the same queued-invocation pattern instead of accessing             //
    //  authState.qmlIntegration directly.                                  //
    // ------------------------------------------------------------------ //
    void uiSetError(const QString& msg);
    void uiBlockInput(bool blocked);
    void uiFocus();

    SAuthState      authState;
    CPolkitListener listener;

    // stateMutex: protects authState and lastAuthResult
    std::mutex stateMutex;

  private:
    SAuthResult lastAuthResult;
};

// Global pointer — defined in Agent.cpp, extern'd by listener/QML integration.
inline CAgent* g_pAgent = nullptr;