#pragma once

#include <vector>
#include <cstddef>
#include <cstring>
#include <string>
#include <algorithm>

// Minimal secure string buffer: holds bytes and overwrites them on destruction.
// Non-copyable to avoid accidental copies.
class SecureString {
  std::vector<char> m_buf;

public:
  SecureString() = default;
  SecureString(const char* data, std::size_t len) {
      if (data && len)
          m_buf.assign(data, data + len);
  }
  SecureString(const std::string& s) {
      m_buf.assign(s.begin(), s.end());
  }

  SecureString(SecureString&& o) noexcept : m_buf(std::move(o.m_buf)) { o.m_buf.clear(); }
  SecureString& operator=(SecureString&& o) noexcept {
      if (this != &o) {
          cleanse();
          m_buf = std::move(o.m_buf);
          o.m_buf.clear();
      }
      return *this;
  }

  SecureString(const SecureString&) = delete;
  SecureString& operator=(const SecureString&) = delete;

  ~SecureString() { cleanse(); }

  const char* data() const noexcept { return m_buf.empty() ? nullptr : m_buf.data(); }
  char* data() noexcept { return m_buf.empty() ? nullptr : m_buf.data(); }
  std::size_t size() const noexcept { return m_buf.size(); }

  void append(const char* d, std::size_t n) {
      if (d && n) m_buf.insert(m_buf.end(), d, d + n);
  }

  void clear() noexcept { cleanse(); m_buf.clear(); }

  // Overwrite contents with zeros.
  void cleanse() noexcept {
      if (!m_buf.empty()) {
          std::fill(m_buf.begin(), m_buf.end(), 0);
          volatile char *p = reinterpret_cast<volatile char*>(m_buf.data());
          for (size_t i = 0; i < m_buf.size(); ++i) p[i] = 0;
      }
  }

  std::string toStdString() const { return std::string(m_buf.begin(), m_buf.end()); }
};
