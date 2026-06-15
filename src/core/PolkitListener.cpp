// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

#include "PolkitListener.hpp"
#include <QDebug>
#include <QInputDialog>
#include "../QMLIntegration.hpp"
#include "Agent.hpp"

#include <print>

using namespace PolkitQt1::Agent;

CPolkitListener::CPolkitListener(QObject* parent) : Listener(parent) {
    ;
}

void CPolkitListener::initiateAuthentication(const QString& actionId,
  const QString& message, const QString& iconName, const PolkitQt1::Details& details,
  const QString& cookie, const PolkitQt1::Identity::List& identities, AsyncResult* result) {

    std::print("> New authentication session\n");

    if (session.inProgress) {
        result->setError("Authentication in progress");
        result->setCompleted();
        std::print("> REJECTING: Another session present\n");
        return;
    }

    if (identities.isEmpty()) {
        result->setError("No identities, this is a problem with your system configuration.");
        result->setCompleted();
        std::print("> REJECTING: No idents\n");
        return;
    }

    session.selectedUser = identities.at(0);
    session.cookie       = cookie;
    session.result       = result;
    session.actionId     = actionId;
    session.message      = message;
    session.iconName     = iconName;
    session.gainedAuth   = false;
    session.cancelled    = false;
    session.inProgress   = true;
    session.attemptCount = 0;
    session.firstAttemptTime = std::chrono::steady_clock::now();

    g_pAgent->initAuthPrompt();

    reattempt();
}

void CPolkitListener::reattempt() {
    session.cancelled = false;

    session.session = new Session(session.selectedUser, session.cookie, session.result);
    connect(session.session, SIGNAL(request(QString, bool)), this, SLOT(request(QString, bool)));
    connect(session.session, SIGNAL(completed(bool)), this, SLOT(completed(bool)));
    connect(session.session, SIGNAL(showError(QString)), this, SLOT(showError(QString)));
    connect(session.session, SIGNAL(showInfo(QString)), this, SLOT(showInfo(QString)));

    session.session->initiate();
}

bool CPolkitListener::initiateAuthenticationFinish() {
    std::print("> initiateAuthenticationFinish()\n");
    return true;
}

void CPolkitListener::cancelAuthentication() {
    std::print("> cancelAuthentication()\n");

    session.cancelled = true;

    finishAuth();
}

void CPolkitListener::request(const QString& request, bool echo) {
    std::print("> PKS request: {} echo: {}\n", request.toStdString(), echo);
}

void CPolkitListener::completed(bool gainedAuthorization) {
    std::print("> PKS completed: {}\n", gainedAuthorization ? "Auth successful" : "Auth unsuccessful");

    session.gainedAuth = gainedAuthorization;

    if (!gainedAuthorization)
        g_pAgent->uiSetError("Authentication failed");

    finishAuth();
}

void CPolkitListener::showError(const QString& text) {
    std::print("> PKS showError: {}\n", text.toStdString());

    g_pAgent->uiSetError(text);
}

void CPolkitListener::showInfo(const QString& text) {
    std::print("> PKS showInfo: {}\n", text.toStdString());
}

void CPolkitListener::finishAuth() {
    if (!session.inProgress) {
        std::print("> finishAuth: ODD. !session.inProgress\n");
        return;
    }

    if (!session.gainedAuth && !session.cancelled) {
        std::print("> finishAuth: Did not gain auth. Reattempting.\n");
        g_pAgent->uiBlockInput(false);
        session.session->deleteLater();
        reattempt();
        return;
    }

    std::print("> finishAuth: Gained auth, cleaning up.\n");

    session.inProgress = false;

    if (session.session) {
        session.session->result()->setCompleted();
        session.session->deleteLater();
    } else
        session.result->setCompleted();

    g_pAgent->resetAuthState();
}

void CPolkitListener::submitPassword(const QString& pass) {
    if (!session.session)
        return;

    // Rate limiting: allow max 5 attempts per minute
    auto now = std::chrono::steady_clock::now();
    if (now - session.firstAttemptTime > std::chrono::minutes(1)) {
        session.firstAttemptTime = now;
        session.attemptCount = 0;
    }
    session.attemptCount++;
    if (session.attemptCount >= 5) {
        // Too many attempts: abort and notify user
        g_pAgent->uiSetError(QStringLiteral("Too many authentication attempts. Please try again later."));
        // Cancel the current session to prevent brute‑force
        cancelPending();
        return;
    }

    session.session->setResponse(pass);
    g_pAgent->uiBlockInput(true);
}

void CPolkitListener::cancelPending() {
    if (!session.session)
        return;

    session.session->cancel();

    session.cancelled = true;

    finishAuth();
}
