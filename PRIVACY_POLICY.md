# Privacy Policy for Usage Notch (CoderBar)

**Effective Date:** September 5, 2026  
**Last Updated:** September 5, 2026  

This Privacy Policy explains how **Usage Notch** (also referred to as "CoderBar", "the Application", "we", "our", or "us"), developed by **malvaLab**, handles your information. 

We are committed to protecting your privacy. **Usage Notch is a privacy-first, local-first macOS utility designed with zero tracking, zero analytics, and zero telemetry.**

---

## 1. Summary: Our Core Privacy Commitment

- **No Tracking or Telemetry:** We do not collect, track, log, profile, or sell any personal data, usage metrics, device identifiers, or analytics.
- **Local-Only Storage:** All credentials, session tokens, and configuration preferences remain stored strictly on your local Mac.
- **Direct API Communication:** Any requests to third-party services (such as Cursor, Anthropic, Google, or OpenAI) are made directly from your Mac to those providers. We operate no intermediary servers, proxy servers, or data collection infrastructure.

---

## 2. Information We Handle and How It Is Used

### A. API Keys and Authentication Tokens
To display your real-time AI quota and token consumption, the Application allows you to configure API keys or session tokens (e.g., Cursor session tokens, Anthropic API keys, Google Gemini keys, OpenRouter keys):
- **Storage:** Stored locally on your Mac using standard macOS local application storage.
- **Transmission:** Transmitted solely and securely via direct, encrypted HTTPS requests from your machine to the respective official API endpoints (for example, `https://cursor.com`, `https://api.anthropic.com`, `https://generativelanguage.googleapis.com`).
- **No Third-Party Access:** These credentials are never transmitted to us, never relayed through any proxy server, and never shared with third parties.

### B. Local Developer Tool Detection (Antigravity, Ollama, etc.)
When checking status for locally running services (such as Google Antigravity or Ollama):
- The Application inspects local process tables and local loopback sockets (`127.0.0.1` / `localhost`) via standard Darwin kernel APIs (`sysctl`, `proc_pidinfo`).
- All queries and responses stay entirely on your local machine. No local socket data or process information is ever transmitted across the internet.

### C. Usage & Quota Metrics
- Metrics retrieved from configured providers (such as remaining fast requests, session percentages, or reset countdowns) are kept in memory and local storage solely to render the UI (the floating notch, edge dock, and menu bar item).
- We do not aggregate, log, or analyze this data.

---

## 3. Third-Party Services and Endpoints

When you configure a provider in Usage Notch, the Application interacts directly with that provider's public API on your behalf:
- **Cursor:** [Cursor Privacy Policy](https://www.cursor.com/privacy)
- **Anthropic (Claude):** [Anthropic Privacy Policy](https://www.anthropic.com/privacy)
- **Google (Antigravity / Gemini):** [Google Privacy Policy](https://policies.google.com/privacy)
- **OpenRouter:** [OpenRouter Privacy Policy](https://openrouter.ai/privacy)
- **OpenAI:** [OpenAI Privacy Policy](https://openai.com/privacy)

Your interactions with these services are governed by their respective privacy policies and terms of service.

---

## 4. Data Retention and Deletion

- You have complete control over your data.
- You can remove any API key, session token, or provider configuration at any time directly in the Application preferences (**Settings / Preferencias**).
- Deleting the Application or clearing its application data from macOS (`UserDefaults`) permanently removes all stored keys, preferences, and cached metrics from your machine.

---

## 5. Children's Privacy

Usage Notch does not knowingly collect or solicit any personal information from children under the age of 13 (or the applicable age in your jurisdiction). The Application is a developer tool that collects no personal data from any user.

---

## 6. Security

We take the security of your local configuration seriously. The Application relies on native macOS sandboxing principles and secure HTTPS (TLS 1.3/1.2) encryption for all network communication with supported provider APIs.

---

## 7. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be posted to this repository with an updated "Last Updated" date. Continued use of the Application after changes are posted constitutes your acceptance of the updated policy.

---

## 8. Contact Information

If you have questions, feedback, or privacy-related concerns regarding Usage Notch, please contact us:

- **GitHub Repository:** [https://github.com/holasoymalva/usage-notch](https://github.com/holasoymalva/usage-notch)
- **Issue Tracker:** [https://github.com/holasoymalva/usage-notch/issues](https://github.com/holasoymalva/usage-notch/issues)
- **Developer:** Martin Manriquez (malvaLab)

---

*This privacy policy meets the requirements of Apple App Store Review Guideline 5.1.1 (Data Collection and Storage).*
