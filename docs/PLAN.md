# MVP Plan — SeeLocals (social events app)

**Name:** SeeLocals
**App ID / bundle ID:** `org.seelocals.app` (set in Step 1; must be final before Step 10)
**Domain:** `seelocals.org` (not yet registered; needed by Step 10)

Free, real-life events and groups. Launch city: Wrocław; data model supports any city.
Platforms: iOS, Android, Web — one Flutter codebase. Payments/donations are **out of scope** for the MVP (see "Later" at the end).

How to use this file: execute one step per Claude session. Start each session with
"Read docs/PLAN.md and CLAUDE.md, then implement Step N." Each step lists its scope and acceptance criteria;
a step is done when every criterion is checked. Mark finished steps with ✅ in this file.

---

## 1. Tech stack

| Area | Choice | Notes |
|---|---|---|
| Client (iOS/Android/Web) | **Flutter** (stable), Dart 3 | One codebase. Web build is a SPA (not SEO-indexable — handled for invite links in Step 10). |
| State management | **Riverpod** (with code generation) | |
| Routing / deep links | **go_router** | Real URLs on web (`/e/:id`, `/g/:id`, `/u/:id`), same routes used by app links. |
| Models | **freezed** + **json_serializable** | |
| i18n | Flutter `gen-l10n` (ARB files) | `en` (primary/fallback), `pl`, `uk`. Selected in settings, defaults to device locale. |
| Backend | **Supabase** (free tier): Postgres, Auth, Storage, Realtime, Edge Functions, pg_cron | `supabase_flutter` SDK. All schema changes as SQL migrations in `supabase/migrations`. Row Level Security on every table. |
| Auth | Supabase Auth: email+password (with email confirmation), Google, **Sign in with Apple** | Apple sign-in is mandatory on iOS once Google is offered. |
| Transactional email | **Resend** (free: 3,000/month) as custom SMTP for Supabase | Supabase's built-in SMTP is rate-limited to a few emails/hour — unusable for real users. |
| Maps | **flutter_map** + **MapTiler** tiles (free tier) | Same map widget on all 3 platforms, no Google billing. |
| Geocoding (address search) | MapTiler Geocoding API (free tier) | Biased to the selected city. |
| "Open in Google Maps" | Plain Google Maps URLs (`https://www.google.com/maps/dir/?api=1&...`) | No API key needed. |
| Routes | GPX import (`gpx` Dart package), drawn as polyline | |
| Recurrence | iCalendar **RRULE** (`rrule` Dart package; same rule string stored in DB) | |
| Media | Supabase Storage (images compressed client-side, videos size/length-limited) | Storage access goes through one `MediaRepository` so it can be swapped for Cloudflare R2 when the 1 GB free limit gets tight. |
| Push notifications | **Firebase Cloud Messaging** (free) via `firebase_messaging`; sent from Supabase Edge Functions | Requires APNs key (Apple dev account) for iOS. |
| Crash reporting | **Sentry** (free tier) | |
| Web hosting | **Cloudflare Pages** (free) + one **Cloudflare Worker** for invite-link previews | |
| CI | GitHub Actions (analyze, test, build web) | iOS builds locally on the Mac via Xcode. |

### Cost for the MVP
| Item | Cost |
|---|---|
| Google Play developer account | $25 one-off |
| Apple Developer Program | $99/year (can be postponed: launch Android + Web first) |
| Domain | ~$10–15/year |
| Supabase, Resend, MapTiler, FCM, Sentry, Cloudflare | $0 (free tiers) |

Upgrade triggers: Supabase Pro ($25/mo) when you have real users (free projects pause after 7 days of inactivity, have no daily backups, 500 MB DB, 1 GB storage); move media to Cloudflare R2 when storage approaches 1 GB.

---

## 2. Product rules (decisions for the MVP)

**Accounts**
- Sign up with email+password (must confirm email before using the app), Google, or Apple.
- 18+ only: date of birth required at onboarding; under 18 → account cannot proceed. (Self-declared; no ID verification in MVP.)
- Profile: 1–5 photos (first = avatar), display name, short bio (≤ 300 chars), interests (pick from a fixed, translated list), preferred language, home city.
- Account deletion and data export available in settings (store + GDPR requirement).

**Cities**
- `cities` table (name in 3 languages, country, timezone, center lat/lng, `is_active`). Only Wrocław active at launch.
- Every event belongs to one city. Users browse by selected city + date range.

**Events**
- Fields: title, description (≤ 2,000 chars), cover image (upload or one of the presets), city, start date-time, end date-time, location (point + address label) **or** route (GPX, with start point), join mode, optional participant limit, optional "cause we support" link (display only; defaults to Foreign Front fundraiser).
- Join mode: `open` (join instantly) or `approval` (organizer approves/rejects requests). A participant limit can be combined with either. When full, the Join button is disabled ("Full"). No waitlist in MVP.
- Organizer can edit or cancel an event; participants get notified.
- Times stored in UTC; displayed and recurrence-calculated in the city's timezone.

**Recurring events & groups**
- Creating a repeating event (e.g., "every Sunday at 19:00", optional end date or count) creates an **event series** and a **group**.
- Occurrences are materialized as normal events for the next 8 weeks; a daily cron job extends the window.
- Joining any occurrence (i.e., becoming an approved participant) automatically adds the user to the group. Group members are **not** auto-joined to future occurrences.
- Group has its own chat and a page listing upcoming occurrences. Users can leave the group.

**Discovery**
- Home feed: city selector + date range (defaults: user's city, today → +30 days), infinite scroll of event cards ordered by start time (keyset pagination). Cancelled and past events hidden.
- Invite links: `https://<domain>/e/<eventId>` and `/g/<groupId>` open the app if installed, otherwise the web app; link previews show title, date, cover.

**Chats**
- Three conversation types: event chat, group chat, direct message.
- Event chat: auto-joined when user becomes a participant; organizer is moderator.
- Messages: text (links clickable), photos (compressed, ≤ 10 per message), videos (≤ 60 s, ≤ 50 MB). Unread counters per conversation.
- Direct messages: any user can message any user. If they share no event/group, the first message arrives as a **message request** the recipient can accept or decline (anti-spam; same pattern as Instagram).

**Safety & moderation**
- Ignore list (block): ignored user cannot DM you, their messages are hidden from you in shared chats, you don't see their events in the feed.
- Report a message or user (reason + optional comment) → goes to the admin queue.
- Strike system: when an admin confirms a report → 1st strike = warning shown in-app; 2nd strike = account blocked. (Admin confirmation prevents mass false reports from banning people.)
- Organizer moderation in their own event/group chat: delete any message, mute a participant (can't post), remove a participant from the event.
- Admin panel: a role-gated section of the same Flutter web app (reports queue, strikes, block/unblock, manage cities, interests, preset covers).
- Rate limits: max messages/minute and max new DM threads/day per user (enforced in DB).

---

## 3. Repository layout

```
/app                 Flutter project (ios, android, web)
  /lib
    /core            theme, router, l10n, env, errors, widgets
    /features/<name> data (repositories), domain (models), presentation (screens, widgets, providers)
  /assets/covers     preset cover SVGs
/supabase
  /migrations        SQL migrations (schema, RLS, functions, cron)
  /functions         Edge Functions (TypeScript/Deno)
  seed.sql
/workers/link-preview  Cloudflare Worker for invite-link OG tags
/docs                PLAN.md, decisions, store texts, privacy policy
CLAUDE.md            conventions for every Claude session
```

---

## 4. Steps

### Step 0 — Local tools (manual, done by you)
Development happens **locally first**: the whole backend runs on your Mac via the Supabase CLI (Docker), and
confirmation/reset emails are caught by the local mail viewer (Mailpit at `http://localhost:54324`), so no
domain or paid accounts are needed until later.

Install: Flutter SDK, Xcode (+ iOS simulator), Android Studio (+ emulator), Docker Desktop, Supabase CLI, Git.
Run `flutter doctor` until it's all green.

Optional now, free, no domain needed: GitHub repo (backup), MapTiler key (map tiles; until then dev uses
OpenStreetMap tiles directly, which is OK for light development use only).

### Accounts — create only when the step that needs them arrives
| Account | Needed at | Cost |
|---|---|---|
| Google Cloud OAuth client (Google sign-in) | Step 3 (can be postponed to the end of Step 3) | free |
| Firebase project (FCM push) | Step 15 | free |
| Domain + Cloudflare | Step 10 (invite links) | ~$10–15/year |
| Supabase cloud project (Frankfurt), Resend (email from your domain), Sentry | Step 16 (deploy) | free tiers |
| Apple Developer Program (Sign in with Apple, TestFlight, push on iOS) | Step 16 | $99/year |
| Google Play Console | Step 16 | $25 one-off |

Testing on your own iPhone works without the paid Apple account (free Apple ID; the app must be re-signed every
7 days). Sign in with Apple, iOS push, and TestFlight need the paid account.

Put all keys in a password manager; Claude will tell you where each one goes.

### Step 1 — Project scaffold
- Flutter project in `/app` with iOS, Android, Web targets; Supabase CLI project in `/supabase`.
- Riverpod, go_router, freezed, gen-l10n (`en`, `pl`, `uk` ARB files with a few strings), flavors/env config (`dev`, `prod`) via `--dart-define`.
- Lints (`very_good_analysis` or `flutter_lints` strict), GitHub Actions: analyze + test + `flutter build web`.
- `CLAUDE.md` with conventions (architecture, naming, "every table has RLS", "every user-facing string goes through l10n", "migrations only, never edit the DB by hand").

**Done when:** app runs on Android emulator, iOS simulator, and Chrome showing a localized placeholder screen; switching locale changes the text; CI is green.

### Step 2 — Design system & assets
- App name/logo placeholder, color palette, typography, light + dark theme (Material 3 tokens).
- Core widgets: buttons, text fields, avatar, event card, empty/error/loading states, bottom navigation (Feed, Groups, Chats, Profile).
- 12 preset event covers as SVGs (abstract shapes/gradients, legible under white title text) + app icon and splash.
- A hidden "gallery" screen showing all components (dev builds only).

**Done when:** gallery shows every component in light and dark on phone and desktop-width web; covers render on all platforms.

### Step 3 — Authentication & onboarding
- Migrations: `profiles` (id = auth user id, display_name, birth_date, bio, home_city_id, locale, role, status, strikes), `cities` (seed Wrocław), `interests` (seed ~40 with 3 translations), `profile_interests`.
- Supabase Auth: email+password with confirmation (Resend SMTP, branded templates in 3 languages), Google, Apple; password reset; deep-link callback handling on all platforms.
- Onboarding: name, birth date (block < 18), home city, language.
- Sign out; delete account (Edge Function deletes user + data + media).

**Done when:** a new user can sign up by each method on Android, iOS, and web; unconfirmed email cannot enter the app; under-18 is blocked; deleting the account removes all their rows and files.

### Step 4 — Profiles
- Edit profile: up to 5 photos (pick, crop, compress, reorder, delete), bio, interests, language (applies immediately), home city.
- View another user's profile (photos carousel, bio, interests, events they organize).
- Storage bucket policies: users write only their own folder.

**Done when:** profile edits persist across devices; another user sees the profile; language switch re-renders the whole app.

### Step 5 — Events (single, non-recurring)
- Migrations: `events` (organizer, city, title, description, cover_url or cover_preset, starts_at, ends_at, location point + address, route_gpx_url, join_mode, capacity, cause_url, status), `event_participants` (status: requested/approved/rejected/left/removed).
- Create/edit flow: cover (upload or preset), title, dates/times (city timezone), location picker (map + address search), description, join mode, capacity, cause link (default prefilled).
- Event details screen: all info, map with pin, "Open in Google Maps", participants avatars, organizer.
- Organizer can cancel (status `cancelled`).

**Done when:** an organizer creates, edits, and cancels an event on every platform; all validations work; times display correctly in Europe/Warsaw regardless of device timezone.

### Step 6 — Routes (GPX)
- Upload GPX on create/edit; parse, validate, compute distance; store file; draw polyline + start/finish markers.
- "Open in Google Maps": start point; plus a directions link with up to 8 evenly sampled waypoints.

**Done when:** a Strava/Komoot GPX shows correctly; Google Maps opens with the route approximated; invalid files show an error.

### Step 7 — Feed & discovery
- City selector + date range picker, infinite scroll (keyset pagination on `starts_at, id`), pull-to-refresh.
- Postgres function `feed_events(city, from, to, cursor)` excluding cancelled, past, and events of ignored users.

**Done when:** scrolling 200 seeded events is smooth with no duplicates or gaps; filters work; feed respects the ignore list (stub table if Step 13 not done).

### Step 8 — Joining & participant management
- Postgres RPC `join_event` (atomic capacity check with row lock), `leave_event`, `approve_request`, `reject_request`, `remove_participant`.
- UI: Join / Request to join / Pending / Joined / Full / Leave states; organizer's requests list.

**Done when:** two users racing for the last spot never exceed capacity (tested); approval flow works end to end.

### Step 9 — Recurring events & groups
- Migrations: `event_series` (rrule, timezone, template fields), `groups` (1:1 with series), `group_members`.
- Repeat UI: none / weekly (choose days) / custom interval; ends never / on date / after N.
- Occurrence materialization for 8 weeks + pg_cron daily extension; edit "this occurrence" vs "all future".
- Trigger: approved participation in any occurrence → add to group. Group page: info, upcoming occurrences, members, leave group.

**Done when:** "every Sunday 19:00" creates correct occurrences across a DST change; joining one adds the user to the group; editing future occurrences doesn't affect past ones.

### Step 10 — Invite links & deep linking
- Universal Links (iOS) and App Links (Android) for `https://<domain>/e/:id` and `/g/:id`; `apple-app-site-association` and `assetlinks.json` served from Cloudflare.
- Cloudflare Worker: for crawler user agents returns HTML with Open Graph tags (title, date, cover); everyone else gets the Flutter web app.
- Share button on event and group pages.

**Done when:** a link pasted into WhatsApp/Messenger/Telegram shows a preview; tapping it opens the app on the right screen (or web if not installed).

### Step 11 — Chat core
- Migrations: `conversations` (type: event/group/direct, ref id), `conversation_members` (role, muted, last_read_at), `messages` (text, attachments jsonb, deleted_at). RLS: only members read/write.
- Auto-membership triggers from event participation and group membership.
- Supabase Realtime subscription, message pagination, unread counters, link detection + tap to open, chats list tab.

**Done when:** two devices exchange messages in real time in event and group chats; leaving an event removes chat access; unread counts are correct.

### Step 12 — Media in chat
- Photo (multi-select, compressed) and video (≤ 60 s, ≤ 50 MB) upload with progress; thumbnails; full-screen viewer with swipe; video player.
- Storage paths per conversation; policies restrict access to members (signed URLs).

**Done when:** photos/videos send and play on all platforms; non-members cannot access the files by URL.

### Step 13 — Direct messages & ignore list
- Start DM from a profile; message requests (accept/decline) when users share no event/group.
- `user_ignores` table; ignore/unignore from profile and chat; effects as in Product rules.
- DB-level rate limits for messages and new DM threads.

**Done when:** DMs work; an ignored user cannot message you and their content is hidden; rate limit triggers a friendly error.

### Step 14 — Moderation & admin panel
- Report message/user (reasons list); `reports`, `strikes` tables.
- Organizer tools in their chats: delete message, mute, remove participant.
- Admin section (web, role = admin): reports queue → confirm (adds strike) / dismiss; 1st strike → warning dialog on next app open; 2nd → status `blocked` (sign-in denied, content hidden); manage cities, interests, preset covers.

**Done when:** full flow tested: report → admin confirms → warning → second confirmed report → blocked user cannot use the app.

### Step 15 — Push notifications
- FCM token registration per device; Edge Function sender; notification preferences in settings.
- Triggers: new message (not in open chat), join request (organizer), request approved/rejected, event changed/cancelled, reminder 2 h before start, new occurrence in your group.

**Done when:** each trigger delivers on Android, iOS, and web; tapping opens the right screen; preferences are respected.

### Step 16 — Launch readiness
- Privacy policy & terms (3 languages), in-app links; community guidelines; contact email.
- Sentry in all builds; basic analytics events (optional, privacy-friendly).
- Store listings: descriptions (3 languages), screenshots, age rating 18+, data-safety forms.
- Seed Wrocław with a few real events (yours/friends') so the feed isn't empty.

**Done when:** TestFlight + Play internal testing builds pass review checklists; web deployed on the production domain.

### Step 17 — Release & feedback loop
Closed beta with 20–50 people in Wrocław → fix → public release.

---

## 5. Later (post-MVP)
- **Donations** (80% charity / 20% app): app-collected payments via Stripe (BLIK, P24, cards) with webhook confirmation, funds held until the event happens, monthly batch transfers to a curated charity list, public transparency page. Needs legal consultation (public collections law, VAT, Apple donation rules) before implementation.
- Waitlists, event ratings/feedback, more cities, interest-based recommendations, moderation automation (AI flagging of spam), media on Cloudflare R2.
