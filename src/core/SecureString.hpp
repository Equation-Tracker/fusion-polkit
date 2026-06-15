// Copyright (c) 2024, Hypr Development
// Copyright (c) 2026, Equation Tracker
// SPDX-License-Identifier: BSD-3-Clause

#pragma once
#include <vector>
#include <cstring>
#include <string>

/**
 * SecureString — a string wrapper that zeroes its buffer on destruction/move.
 *
 * Intended for passwords and other sensitive in-memory data.
 * Copy is disabled; only move semantics are allowed.
 */
class SecureString {
  public:
    SecureString() = default;

    explicit SecureString(const char* data, size_t len) : m_buf(data, data + len) {}

    ~SecureString() { cleanse(); }

    // Copy is disabled — sensitive data should not be duplicated carelessly.
    SecureString(const SecureString&)            = delete;
    SecureString& operator=(const SecureString&) = delete;

    SecureString(SecureString&& o) noexcept : m_buf(std::move(o.m_buf)) {
        // moved-from vector is now empty; no cleanse needed on o
    }

    SecureString& operator=(SecureString&& o) noexcept {
        if (this != &o) {
            cleanse();              // wipe our current buffer before overwriting
            m_buf = std::move(o.m_buf);
            // moved-from o.m_buf is now empty — no further action needed
        }
        return *this;
    }

    [[nodiscard]] const char* data() const noexcept { return m_buf.data(); }
    [[nodiscard]] size_t      size() const noexcept { return m_buf.size(); }
    [[nodiscard]] bool        empty() const noexcept { return m_buf.empty(); }

    /**
     * Securely zero every byte in the buffer, then release the allocation.
     */
    void cleanse() noexcept {
        if (!m_buf.empty()) {
#if defined(__GLIBC__) && (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 25))
            explicit_bzero(m_buf.data(), m_buf.size());
#elif defined(_WIN32)
            SecureZeroMemory(m_buf.data(), m_buf.size());
#elif defined(__STDC_LIB_EXT1__)
            memset_s(m_buf.data(), m_buf.size(), 0, m_buf.size());
#else
            // Best-effort volatile loop — adequate for most toolchains in practice.
            volatile char* p = reinterpret_cast<volatile char*>(m_buf.data());
            for (size_t i = 0; i < m_buf.size(); ++i)
                p[i] = 0;
#endif
            m_buf.clear();
        }
    }

    [[nodiscard]] std::string toStdString() const {
        return std::string(m_buf.begin(), m_buf.end());
    }

  private:
    std::vector<char> m_buf;
};