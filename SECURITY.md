# Security Policy

## Supported Versions

We release patches and security updates for the current major version of the Sprout Recipe App.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## Security Architecture & Design Principles

Sprout is engineered with a strict **Defense in Depth** approach:

1. **Zero Client-Side Secrets**:
   - AI service API keys (`GEMINI_API_KEY`, `GROQ_API_KEY`) are **never bundled in client binaries** or exposed to client-side reverse engineering.
   - All AI inference (vision scanning, nutrition breakdown, recipe translation, and culinary substitutions) is routed through secure **Supabase Edge Functions** (`supabase/functions/sprout-ai`), where keys reside safely as server-side environment secrets.

2. **Row-Level Security (RLS)**:
   - All database tables in Supabase enforce granular RLS policies.
   - Client requests use public, publishable anonymous keys (`sb_publishable_...`) that only permit access to authorized rows and public recipe records.

3. **Secure Local Storage**:
   - Sensitive user preferences and cached tokens are encrypted on-device via `flutter_secure_storage` (Android Keystore / iOS Keychain).

4. **Input Sanitization & AI Prompt Hardening**:
   - System prompts in edge functions enforce strict JSON schema output parsing to prevent prompt injection and malformed model hallucination payloads.

---

## Reporting a Vulnerability

If you discover a security vulnerability in Sprout, please follow responsible disclosure:

1. **Do NOT report security issues via public GitHub issues.**
2. Send an email to the project maintainer at **krishh19.dev@gmail.com** with:
   - A clear description of the vulnerability.
   - Steps to reproduce or proof-of-concept (PoC) code.
   - Potential impact of the issue.
3. You will receive an acknowledgment within **48 hours**.
4. We will coordinate a timeline for remediation and public advisory release.

Thank you for helping keep Sprout and our users safe!
