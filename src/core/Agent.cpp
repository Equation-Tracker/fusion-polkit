#define POLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE 1

#include <polkitagent/polkitagent.h>
#include <print>
#include <QtCore/QString>
#include <memory>
using namespace Qt::Literals::StringLiterals;

#include "Agent.hpp"
#include "../QMLIntegration.hpp"

CAgent::CAgent() {
    ;
}

CAgent::~CAgent() {
    ;
}

bool CAgent::start() {
    sessionSubject = makeShared<PolkitQt1::UnixSessionSubject>(getpid());

    listener.registerListener(*sessionSubject, "/org/hyprland/PolicyKit1/AuthenticationAgent");

    int argc = 1;
    const char* argv[] = {"hyprpolkitagent"};
    QApplication app(argc, const_cast<char**>(argv));

    app.setApplicationName("Hyprland Polkit Agent");
    QGuiApplication::setQuitOnLastWindowClosed(false);

    app.exec();

    return true;
}

void CAgent::resetAuthState() {
    if (authState.authing) {
        authState.authing = false;
        // Unique_ptr will clean up automatically
        authState.qmlEngine.reset();
        authState.qmlIntegration.reset();
    }
}

void CAgent::initAuthPrompt() {
    resetAuthState();

    if (!listener.session.inProgress) {
        std::print(stderr, "INTERNAL ERROR: Spawning qml prompt but session isn't in progress\n");
        return;
    }

    std::print("Spawning qml prompt\n");

    authState.authing = true;

    authState.qmlIntegration = std::make_unique<CQMLIntegration>();

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle("org.hyprland.style");

    authState.qmlEngine = std::make_unique<QQmlApplicationEngine>();
    authState.qmlEngine->rootContext()->setContextProperty("hpa", authState.qmlIntegration.get());
    authState.qmlEngine->load(QUrl{u"qrc:/qt/qml/hpa/qml/main.qml"_s});

    authState.qmlIntegration->focusField();
}

bool CAgent::resultReady() {
    return !lastAuthResult.used;
}

void CAgent::submitResultThreadSafe(std::string result) {
    lastAuthResult.used   = false;
    lastAuthResult.result = result;

    const bool PASS = result.starts_with("auth:");

    // Avoid logging sensitive password information
    std::print("Got result from qml: {}\n", PASS ? "auth:<redacted>" : result);

    if (PASS) {
        // Submit password
        listener.submitPassword(result.substr(result.find(":") + 1).c_str());
        // Securely erase password from memory
        std::fill(result.begin(), result.end(), '\0');
        result.clear();
    } else {
        listener.cancelPending();
    }
}
