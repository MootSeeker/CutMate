# CutMate – Fact Sheet

**Version:** 0.4 (Draft – updated)
**Last updated:** 27 May 2025

## 1. Purpose & Value Proposition

* CutMate is your AI wingman for cutting weight—helping young men shed kilos without overthinking food.
* Combines personalised goal‑setting, progress tracking, nutrition insights, AI‑generated meal suggestions, and viral shareables (meal cards, milestone GIFs).
* **Differentiator:** habit‑building with minimal cognitive load; allergy‑aware AI meal guidance that adapts to the user’s pantry and creates share‑worthy visuals.

## 2. Target Audience

* **Primary:** males aged **18–35** aiming to lose 5–20 kg.
* **Secondary:** future expansion to broader demographics & maintenance users.
* **Geographic focus:** Global English‑speaking markets (v1).
* **Accessibility considerations:** localisation‑ready framework, dyslexia‑friendly fonts, voiceover support.

## 3. Business & Success Metrics

* **Business model:** Freemium with optional Premium subscription (monthly or annual).
* **KPIs:** WAU, 7‑day retention, avg. weight change after 12 weeks, conversion to paid, number of shared meal cards/GIFs.
* **Exit criteria:** MVP deemed successful when ≥30 % 4‑week retention, ≥4★ rating, ≥20 % of DAU share at least one card/GIF per week.

## 4. Core Features (MVP)

| # | Feature                    | Description                                         | Priority | Notes                                                    |
| - | -------------------------- | --------------------------------------------------- | -------- | -------------------------------------------------------- |
| 1 | Onboarding & Goal Setup    | Collect baseline weight, target, timeframe          | **P0**   | Granular goal sliders?                                   |
| 2 | Daily Weight & Food Log    | Manual input of weight & meals (v1)                 | **P0**   | Barcode scanner later                                    |
| 3 | **AI Meal Recommendation** | LLM suggests next meal based on metrics & pantry    | **P0**   | Optimises calories/macros; allergy‑aware; open food data |
| 4 | **Shareable Meal Card**    | Auto‑renders image of AI meal suggestion for social | **P0**   | Viral hook #1                                            |
| 5 | **Milestone GIF**          | Animated –1 kg/–5 kg celebration GIF                | **P0**   | Viral hook #2                                            |
| 6 | Progress Dashboard         | Charts of weight, trend, streaks                    | P0       | Chart libs in Flutter                                    |
| 7 | Habit Builder              | Select habits (water, steps) & reminders            | P1       | Custom habits?                                           |
| 8 | Educational Content        | Evidence‑based micro‑lessons                        | P1       | Source content in‑house?                                 |
| 9 | Social / Accountability    | Invite friend or coach                              | P2       | GDPR impact?                                             |

## 5. Extended Features (Post‑MVP)

* AI chat‑coach.
* Meal plan generator & grocery list.
* Wearable integration (Apple Watch / Fitbit).
* Streak Badge & 30‑Day Leaderboard (additional viral hooks).
* Challenges & gamification.

## 6. Non‑Functional Requirements

| Aspect        | Target                                                                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Platforms     | Cross‑platform (Flutter ≥ 3.x) preferred; fallback to native iOS (SwiftUI) if blockers                                                     |
| Performance   | Cold start < 2 s on mid‑range devices                                                                                                      |
| Offline       | Core logging offline, sync on reconnect                                                                                                    |
| Security      | AES‑256 at rest, TLS 1.3 in transit                                                                                                        |
| Privacy       | GDPR, Swiss DPA compliant; explicit AI consent banner; data retained 3 years or ≤ 1 year after user deletion; **data‑storage region: TBD** |
| Accessibility | WCAG 2.1 AA                                                                                                                                |

## 7. Compliance & Health Regulations

* Classified as *lifestyle* app (non‑medical) → avoid MDR class IIa.
* Clear disclaimer & CE marking check for EU market.

## 8. Technical Architecture

```plaintext
[Flutter UI] ↔ [Bloc/Provider state] ↔ [Domain Layer] ↔ [REST/GraphQL API] ↔ [PostgreSQL]
                                              ↕
                                   [Third‑party APIs]
```

* **Cloud:** AWS (EU) vs Firebase (EU) – cost‑driven.
* **CI/CD:** GitHub Actions → TestFlight / Play Console.
* **AI service:** OpenAI (usage cap €50/month) with automatic fallback to self‑hosted Mistral‑7B‑Instruct when 80 % budget reached.

## 9. Data Model (High‑Level)

* **User** (id, email, auth\_provider, dob, height…).
* **WeightEntry** (date, value\_kg, source).
* **MealSuggestion** (datetime, ingredients\_in, recipe\_out, calories\_est).
* **MealShareCard** (id, meal\_suggestion\_id, image\_url, shared\_at).
* **MilestoneEvent** (type, value, gif\_url, shared\_at).
* **HabitEntry** (habit\_id, date, completed).

## 10. Integration Points

* USDA SR Legacy & OpenFoodFacts.
* Stripe for payments.
* Apple HealthKit / Google Fit – post‑MVP.

## 11. Analytics & Telemetry

* Mixpanel / Firebase Analytics events.
* Track: meal card created, GIF shared, share‑to‑install conversions.
* A/B testing framework.

## 12. Team & Budget

| Role                           | FTE                                             | Notes                             |
| ------------------------------ | ----------------------------------------------- | --------------------------------- |
| Founder‑Developer (full‑stack) | 1.0                                             | Sole contributor                  |
| Design                         | 0                                               | Use open‑source UI kits initially |
| QA                             | 0                                               | Manual testing + beta crowd       |
| Budget                         | €0 bootstrapped; €50/mo OpenAI; free tiers else |                                   |

## 13. Roadmap & Milestones

| Phase         | Timeline     | Deliverables                              |
| ------------- | ------------ | ----------------------------------------- |
| Discovery     | Jun 2025     | Product spec finalised, 8 user interviews |
| MVP Dev       | Jul–Sep 2025 | iOS TestFlight beta                       |
| Beta Feedback | Oct 2025     | Iterate, tighten viral flows              |
| GA Launch     | Nov 2025     | iOS & Android store release               |

## 14. Glossary

* **MVP:** Minimum Viable Product
* **KPI:** Key Performance Indicator
* **GDPR:** General Data Protection Regulation

## 15. Open Questions / Assumptions

1. Final data‑storage region decision?
2. Need for professional review by dietitians?
3. Integration with hardware scales (post‑MVP)?
4. Visual identity (logo finalisation, brand guidelines)?
5. Acceptable trade‑offs for cross‑platform vs native performance?
6. Post‑launch support expectations?

---

*This document is a living artifact; update sections as decisions are made.*
