#include "core/Agent.hpp"
// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

int main(int argc, char* argv[]) {
    g_pAgent = std::make_unique<CAgent>();

    return g_pAgent->start() == false ? 1 : 0;
}
