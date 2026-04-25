# Tahanan Product Specification, Features, and MVP

## 1) Product Overview
Tahanan is a family care and connection app designed to help family members stay in touch through daily check-ins, reminders, health support, and emergency signals.

Primary goal:
- Help families coordinate care and communicate quickly, especially for seniors or members needing regular support.

## 2) Product Vision
Build a private family space where each member can:
- Share wellness status quickly
- Receive and manage reminders
- Check in on other family members
- Contact family members instantly through message and call actions
- Raise emergency alerts when needed

## 3) Target Users
- Family members caring for parents, grandparents, children, or dependents
- Adults coordinating household health and routines
- Users who need medication or personal reminders

## 4) Core User Problems Solved
- "I do not know how my family member is feeling today."
- "I forget important medicine or wellness tasks."
- "I need to check on someone quickly."
- "I need to contact a family member immediately from the app."
- "I need a simple emergency signal to alert family."

## 5) Platform and Tech Stack
Frontend:
- Flutter (cross-platform mobile)
- Dio for API networking
- Shared preferences for token persistence
- flutter_map for map display
- url_launcher for direct phone call and SMS actions

Backend:
- Django + Django REST Framework
- JWT authentication
- SQLite for local development

## 6) Functional Specifications

### 6.1 Authentication and Account
- User can register
- User profile can be retrieved and updated

### 6.2 Family Membership
- User can join a family by family ID
- User can view family members in the same family

### 6.3 Dashboard
- Display personalized greeting
- Mood check-in with selectable moods
- Mood-specific encouragement message after check-in
- Show next most relevant medicine reminder in dashboard panel
- Quick family message posting
- Family notes feed display

### 6.4 Family Tab
- Show family members with mood indicators
- Family map panel with geotag locations (if available)
- "Check on them" action for each member
- Family check-in modal with:
  - Check on them
  - Message action (opens SMS app using member phone)
  - Call action (opens dialer using member phone)
- Message and Call actions are disabled when no phone number exists

### 6.5 Reminders Tab
- View reminders assigned to current user
- Add reminder with title, notes, date/time, and assignment
- Mark reminder as Done
- Dismiss reminder
- Reminder card should vanish immediately from list after Done or Dismiss

### 6.6 Medicines
- Load medicine reminders from API
- Mark medicine as taken
- Handle overdue or skip message states

### 6.7 Emergency Support
- Toggle emergency state on/off
- Family members can see emergency-related context through family data

## 7) Data and Domain Specifications

### 7.1 User Data (high-level)
- id
- username
- first_name
- last_name
- email
- phone
- birthday
- mood
- checked_on
- in_emergency
- family reference
- optional geotag

### 7.2 Family Member Data (frontend usage)
- id
- username
- first_name
- mood
- in_emergency
- phone
- latitude / longitude (from geotag when present)

### 7.3 Reminder Data (high-level)
- id
- title
- description
- remind_at
- assigned users
- status fields (active/done/dismissed behavior via endpoints)

### 7.4 Medicine Data (high-level)
- id
- name
- dosage
- scheduled_time
- taken status for today
- overdue and skip message context

## 8) API and Integration Specifications (summary)
- Authentication:
  - POST /api/auth/register/
  - POST /api/auth/login/
  - POST /api/auth/token/refresh/
- User:
  - GET /api/users/me/
  - PATCH /api/users/me/
  - PATCH /api/users/emergency/toggle/
  - PATCH /api/users/{id}/check-on/
- Family:
  - GET /api/families/{id}/members/
  - POST /api/families/{id}/join/
- Reminders:
  - GET /api/reminders/mine/
  - GET/POST /api/reminders/
  - PATCH /api/reminders/{id}/done/
  - PATCH /api/reminders/{id}/dismiss/
- Medicines:
  - GET/POST /api/medicines/
  - PATCH /api/medicines/{id}/take/
- Notes:
  - GET/POST /api/notes/

## 9) MVP Definition

### 9.1 MVP Objective
Deliver a stable first release that enables families to:
- Authenticate
- Join family groups
- Track mood and wellbeing
- Manage reminders and medicine check-ins
- Check on relatives and contact them quickly

### 9.2 MVP In-Scope Features
1. Authentication (register, login, token refresh)
2. User profile fetch/update including mood
3. Family membership and family member list
4. Dashboard mood check-in and encouragement message
5. Dashboard medicine panel showing the next closest reminder
6. Family check-in flow with Check on them action
7. Family modal Message and Call via phone field
8. Reminders list, add reminder, done, dismiss
9. Immediate UI removal of reminder after done/dismiss
10. Emergency toggle action

### 9.3 MVP Out of Scope (Post-MVP)
- Push notifications and background scheduling reliability
- In-app real-time chat
- Video calls
- Rich analytics dashboards
- Advanced reminder recurrence rules
- Role-based family permissions and moderation tools
- Offline-first sync conflict handling

## 10) MVP Acceptance Criteria
- User can complete register and login without manual backend fixes
- User can join a family and view members
- Mood update is reflected in dashboard and persisted via API
- Family check-in modal opens and supports Check on, Message, and Call actions
- If member has no phone, Message/Call buttons are disabled
- Reminders can be created and assigned
- Reminder disappears from UI immediately when Done or Dismiss is pressed
- Medicine panel shows one next most relevant reminder
- Emergency toggle succeeds and returns visible success feedback

## 11) Non-Functional Requirements
- Responsive UI for common mobile form factors
- Graceful API failure handling with user feedback where appropriate
- JWT-protected endpoints for private data actions
- Maintainable feature-based frontend structure
- Development setup should run locally with documented steps

## 12) Current Project Structure (high-level)
- backend/api: Django project, REST endpoints, models, serializers, views
- frontend/lib/core: shared API client, token store, app models
- frontend/lib/features/auth: auth UI and flows
- frontend/lib/features/dashboard: dashboard UI and actions
- frontend/lib/features/family: family UI, map, check-in modal actions
- frontend/lib/features/reminders: reminder list and creation flows

## 13) Future Enhancements (Post-MVP)
- Reminder notifications (local + push)
- Smart care suggestions from mood/reminder patterns
- Family activity timeline and audit trail
- Better map privacy controls and geofence alerts
- Accessibility improvements and localization polish

## 14) Definition of Done for MVP Release
- All MVP acceptance criteria validated in QA pass
- No blocking crashes in core user journeys
- README setup steps verified on a clean machine
- API documentation aligned with actual implemented endpoints
