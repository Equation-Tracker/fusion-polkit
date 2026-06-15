#pragma once

#include <QObject>
#include <QString>

#include <polkitqt1-agent-listener.h>
#include <polkitqt1-identity.h>
#include <polkitqt1-details.h>
#include <polkitqt1-agent-session.h>
#include <chrono>
#include <mutex>

class CPolkitListener : public PolkitQt1::Agent::Listener {
    Q_OBJECT;
    Q_DISABLE_COPY(CPolkitListener);

  public:
    CPolkitListener(QObject* parent = nullptr);
    ~CPolkitListener() override {};

    void submitPassword(const QString& pass);
    void cancelPending();

  public Q_SLOTS:
    void initiateAuthentication(const QString& actionId, const QString& message, const QString& iconName, const PolkitQt1::Details& details, const QString& cookie,
                                const PolkitQt1::Identity::List& identities, PolkitQt1::Agent::AsyncResult* result) override;
    bool initiateAuthenticationFinish() override;
    void cancelAuthentication() override;

    void request(const QString& request, bool echo);
    void completed(bool gainedAuthorization);
    void showError(const QString& text);
    void showInfo(const QString& text);

  private:
    struct {
        bool                           inProgress = false, cancelled = false, gainedAuth = false;
        QString                        cookie, message, iconName, actionId;
        PolkitQt1::Agent::AsyncResult* result = nullptr;
        PolkitQt1::Identity            selectedUser;
        PolkitQt1::Agent::Session*    session = nullptr;
        int                            attemptCount = 0;
        std::chrono::steady_clock::time_point firstAttemptTime = std::chrono::steady_clock::now();
    } session;

    void reattempt();
    void finishAuth();

    friend class CAgent;
    friend class CQMLIntegration;
};
