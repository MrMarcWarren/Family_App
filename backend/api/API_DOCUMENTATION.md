# Family App — REST API Documentation

**Base URL:** `http://<host>/api/`  
**Auth:** JWT Bearer Token — include `Authorization: Bearer <access_token>` on all protected endpoints.  
**Content-Type:** `application/json`

---

## Authentication

### POST `/api/auth/login/`
Obtain a JWT access + refresh token pair.

**Auth required:** No

**Request body:**
```json
{
  "username": "john",
  "password": "secret123"
}
```

**Response `200`:**
```json
{
  "access": "<jwt_access_token>",
  "refresh": "<jwt_refresh_token>"
}
```

---

### POST `/api/auth/token/refresh/`
Get a new access token using a refresh token.

**Auth required:** No

**Request body:**
```json
{
  "refresh": "<jwt_refresh_token>"
}
```

**Response `200`:**
```json
{
  "access": "<new_jwt_access_token>"
}
```

---

### POST `/api/auth/register/`
Register a new user account. The user will have no family assigned until they join one.

**Auth required:** No

**Request body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `username` | string | Yes | Unique |
| `email` | string | No | |
| `password` | string | Yes | Must pass Django password validators |
| `password2` | string | Yes | Must match `password` |
| `first_name` | string | No | |
| `last_name` | string | No | |
| `phone` | string | No | |
| `birthday` | date | No | Format: `YYYY-MM-DD` |
| `mood` | string | No | `sad`, `happy`, `excited`, `crying`, `angry` |
| `is_adult` | boolean | No | Default: `false` |
| `geotag` | object | No | See GeoTag object below |

**GeoTag object (optional, nested inside register):**
```json
{
  "latitude": 3.147857,
  "longitude": 101.695721,
  "label": "Home",
  "address": "123 Jalan Ampang, KL"
}
```

**Request example:**
```json
{
  "username": "john",
  "email": "john@example.com",
  "password": "StrongPass123!",
  "password2": "StrongPass123!",
  "first_name": "John",
  "last_name": "Doe",
  "is_adult": true
}
```

**Response `201`:**
```json
{
  "id": 1,
  "username": "john",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": null,
  "birthday": null,
  "mood": "happy",
  "in_emergency": false,
  "is_adult": true,
  "family": null
}
```

---

## Users

### GET `/api/users/me/`
Get the currently authenticated user's profile.

**Auth required:** Yes

**Response `200`:**
```json
{
  "id": 1,
  "username": "john",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "0123456789",
  "birthday": "1990-05-15",
  "mood": "happy",
  "mood_display": "Happy",
  "mood_updated_at": "2026-04-26T08:00:00Z",
  "in_emergency": false,
  "is_adult": true,
  "checked_on": false,
  "geotag": {
    "id": 1,
    "latitude": "3.147857",
    "longitude": "101.695721",
    "label": "Home",
    "address": "123 Jalan Ampang, KL",
    "created_at": "2026-04-01T10:00:00Z",
    "updated_at": "2026-04-01T10:00:00Z"
  },
  "family": {
    "id": 1
  },
  "date_joined": "2026-04-01T09:00:00Z"
}
```

---

### PUT / PATCH `/api/users/me/`
Update the current user's profile. Use `PATCH` for partial updates.

**Auth required:** Yes

**Request body (all fields optional for PATCH):**
| Field | Type | Notes |
|---|---|---|
| `first_name` | string | |
| `last_name` | string | |
| `email` | string | |
| `phone` | string | |
| `birthday` | date | `YYYY-MM-DD` |
| `mood` | string | `sad`, `happy`, `excited`, `crying`, `angry` |
| `family_id` | integer | ID of the family to assign (use join endpoint instead) |

**Request example (PATCH):**
```json
{
  "mood": "excited",
  "phone": "0198887777"
}
```

**Response `200`:** Same shape as `GET /api/users/me/`

---

### PATCH `/api/users/change-password/`
Change the current user's password.

**Auth required:** Yes

**Request body:**
```json
{
  "old_password": "OldPass123!",
  "new_password": "NewPass456!",
  "new_password2": "NewPass456!"
}
```

**Response `200`:**
```json
{
  "message": "Password changed successfully."
}
```

**Error `400`:**
```json
{
  "old_password": "Incorrect password."
}
```

---

### PATCH `/api/users/emergency/toggle/`
Toggle the current user's emergency status on or off.

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "message": "Emergency status set to ON.",
  "in_emergency": true
}
```

---

### PATCH `/api/users/{id}/check-on/`
Mark a family member as checked-on. Both users must be in the same family.

**Auth required:** Yes

**URL param:** `id` — the target user's ID

**Request body:** None

**Response `200`:**
```json
{
  "message": "Checked on successfully."
}
```

**Errors:**
- `400` — Cannot check on yourself
- `403` — Target user is not in your family

---

### PATCH `/api/users/dismiss-check-on/`
Dismiss your own checked-on status (reset to `false`).

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "message": "Check-on dismissed.",
  "checked_on": false
}
```

---

### GET `/api/users/emergency/list/`
List all users currently in emergency status.

**Auth required:** Yes — Admin only

**Response `200`:**
```json
[
  {
    "id": 3,
    "username": "jane",
    "first_name": "Jane",
    "in_emergency": true,
    ...
  }
]
```

---

### GET `/api/users/`
List all users.

**Auth required:** Yes — Admin only

**Response `200`:** Array of user objects (same shape as `GET /api/users/me/`)

---

### DELETE `/api/users/{id}/`
Delete a user account.

**Auth required:** Yes — Admin only

**Response `204`:** No content

---

## GeoTags

### POST `/api/geotags/`
Create a geotag and attach it to the current user. Each user can only have one geotag.

**Auth required:** Yes

**Request body:**
```json
{
  "latitude": 3.147857,
  "longitude": 101.695721,
  "label": "Home",
  "address": "123 Jalan Ampang, KL"
}
```

**Response `201`:**
```json
{
  "id": 1,
  "latitude": "3.147857",
  "longitude": "101.695721",
  "label": "Home",
  "address": "123 Jalan Ampang, KL",
  "created_at": "2026-04-26T10:00:00Z",
  "updated_at": "2026-04-26T10:00:00Z"
}
```

**Error `400`:** GeoTag already exists — use PUT/PATCH to update.

---

### GET `/api/geotags/me/`
Get the current user's geotag.

**Auth required:** Yes

**Response `200`:** GeoTag object (same shape as POST response)

**Error `404`:** No geotag found.

---

### PUT / PATCH `/api/geotags/me/`
Update the current user's geotag.

**Auth required:** Yes

**Request body:** Same fields as POST (all optional for PATCH)

**Response `200`:** Updated GeoTag object

---

### DELETE `/api/geotags/me/`
Remove the current user's geotag.

**Auth required:** Yes

**Response `204`:** No content

---

## Families

### GET `/api/families/`
List families. Regular users see only their own family. Admins see all.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": 1,
    "name": "The Lims",
    "total_members": 4,
    "members": [ ... ],
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-04-26T00:00:00Z"
  }
]
```

---

### POST `/api/families/`
Create a new family.

**Auth required:** Yes — Admin only

**Request body:**
```json
{
  "name": "The Lims"
}
```

**Response `201`:**
```json
{
  "id": 1
}
```

---

### GET `/api/families/{id}/`
Get full details of a family, including all members.

**Auth required:** Yes — must be a member of the family or admin

**Response `200`:**
```json
{
  "id": 1,
  "name": "The Lims",
  "total_members": 3,
  "members": [
    {
      "id": 1,
      "username": "john",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "0123456789",
      "mood": "happy",
      "in_emergency": false,
      "is_adult": true,
      "geotag": {
        "id": 1,
        "latitude": "3.147857",
        "longitude": "101.695721",
        "label": "Home",
        "address": "123 Jalan Ampang, KL",
        "created_at": "2026-04-01T10:00:00Z",
        "updated_at": "2026-04-01T10:00:00Z"
      }
    }
  ],
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-04-26T00:00:00Z"
}
```

---

### POST `/api/families/{id}/join/`
Join a family. The user must not already belong to a family.

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "message": "You have joined The Lims."
}
```

**Errors:**
- `400` — Already in a family
- `404` — Family not found

---

### POST `/api/families/{id}/add-member/`
Add another registered user to this family. Caller must be an adult or admin.

**Auth required:** Yes — Adult or Admin

**Request body:**
```json
{
  "user_id": 5
}
```

**Response `200`:**
```json
{
  "message": "jane added to The Lims."
}
```

**Errors:**
- `403` — Only adults can add members
- `404` — User not found

---

### POST `/api/families/{id}/remove-member/`
Remove a user from this family. Caller must be an adult or admin.

**Auth required:** Yes — Adult or Admin

**Request body:**
```json
{
  "user_id": 5
}
```

**Response `200`:**
```json
{
  "message": "jane removed from The Lims."
}
```

**Errors:**
- `403` — Only adults can remove members
- `404` — User not found in this family

---

### GET `/api/families/{id}/members/`
List all members of a family.

**Auth required:** Yes — must be a member or admin

**Response `200`:** Array of family member objects (same shape as members array in `GET /api/families/{id}/`)

---

### GET `/api/families/{id}/emergency/`
List family members currently in emergency.

**Auth required:** Yes — must be a member or admin

**Response `200`:** Array of family member objects where `in_emergency: true`

---

### DELETE `/api/families/{id}/`
Delete a family.

**Auth required:** Yes — Admin only

**Response `204`:** No content

---

## Notes

> Notes are immutable — they cannot be edited after creation.

### GET `/api/notes/`
List notes. If the user has a family, returns all notes by family members. Otherwise returns only the user's own notes.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": 1,
    "creator": "john",
    "content": "Don't forget dad's appointment on Friday.",
    "created_at": "2026-04-26T08:30:00Z"
  }
]
```

---

### POST `/api/notes/`
Create a note. Creator is set automatically from the logged-in user.

**Auth required:** Yes

**Request body:**
```json
{
  "content": "Don't forget dad's appointment on Friday."
}
```

**Response `201`:**
```json
{
  "id": 1,
  "creator": "john",
  "content": "Don't forget dad's appointment on Friday.",
  "created_at": "2026-04-26T08:30:00Z"
}
```

> Max length: 280 characters.

---

### GET `/api/notes/mine/`
List only the current user's notes.

**Auth required:** Yes

**Response `200`:** Array of note objects

---

### DELETE `/api/notes/{id}/`
Delete a note. Only the creator can delete it.

**Auth required:** Yes

**Response `204`:** No content

---

## Reminders

### GET `/api/reminders/`
List all reminders that were created by or assigned to the current user.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": 1,
    "creator": "john",
    "assigned_to": ["jane", "bob"],
    "title": "Take medicine",
    "description": "Blood pressure pill",
    "remind_at": "2026-04-27T08:00:00Z",
    "statuses": [
      { "user": "jane", "status": "pending", "status_display": "Pending", "updated_at": "2026-04-26T10:00:00Z" },
      { "user": "bob", "status": "done", "status_display": "Done", "updated_at": "2026-04-27T08:05:00Z" }
    ],
    "created_at": "2026-04-26T07:00:00Z",
    "updated_at": "2026-04-26T07:00:00Z"
  }
]
```

---

### POST `/api/reminders/`
Create a reminder. All assignees must be in the same family as the creator.

**Auth required:** Yes

**Request body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | Yes | Max 100 chars |
| `remind_at` | datetime | Yes | ISO 8601: `2026-04-27T08:00:00Z` |
| `assigned_to_ids` | array of int | Yes | Array of user IDs to assign |
| `description` | string | No | |

**Request example:**
```json
{
  "title": "Take medicine",
  "description": "Blood pressure pill",
  "remind_at": "2026-04-27T08:00:00Z",
  "assigned_to_ids": [2, 3]
}
```

**Response `201`:** Reminder object (same shape as GET list item)

---

### GET `/api/reminders/{id}/`
Get a single reminder.

**Auth required:** Yes

**Response `200`:** Reminder object

---

### PUT / PATCH `/api/reminders/{id}/`
Update a reminder.

**Auth required:** Yes

**Request body:** Same fields as POST (all optional for PATCH)

**Response `200`:** Updated reminder object

---

### DELETE `/api/reminders/{id}/`
Delete a reminder.

**Auth required:** Yes

**Response `204`:** No content

---

### GET `/api/reminders/mine/`
Reminders assigned to the current user.

**Auth required:** Yes

**Response `200`:** Array of reminder objects

---

### GET `/api/reminders/created/`
Reminders created by the current user.

**Auth required:** Yes

**Response `200`:** Array of reminder objects

---

### GET `/api/reminders/pending/`
Reminders assigned to the current user with status `pending`.

**Auth required:** Yes

**Response `200`:** Array of reminder objects

---

### PATCH `/api/reminders/{id}/done/`
Mark a reminder as done for the current user.

**Auth required:** Yes — must be assigned to this reminder

**Request body:** None

**Response `200`:**
```json
{
  "message": "Reminder marked as done.",
  "status": "done"
}
```

**Error `403`:** This reminder is not assigned to you.

---

### PATCH `/api/reminders/{id}/dismiss/`
Dismiss a reminder for the current user.

**Auth required:** Yes — must be assigned to this reminder

**Request body:** None

**Response `200`:**
```json
{
  "message": "Reminder dismissed.",
  "status": "dismissed"
}
```

**Error `403`:** This reminder is not assigned to you.

---

### GET `/api/reminders/family/`
List reminders assigned to other family members (excludes your own).

**Auth required:** Yes — must be in a family

**Response `200`:** Array of reminder objects

**Error `403`:** You are not part of a family.

---

### GET `/api/reminders/user/{id}/`
List reminders assigned to a specific family member.

**Auth required:** Yes — must be in the same family as the target user

**URL param:** `id` — target user's ID

**Response `200`:** Array of reminder objects

**Errors:**
- `403` — You are not part of a family
- `404` — User not found in your family

---

## Medicines

### GET `/api/medicines/`
List all medicines belonging to the current user.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": 1,
    "user": "john",
    "name": "Amlodipine",
    "dosage": "5mg",
    "scheduled_time": "08:00:00",
    "is_active": true,
    "last_taken_at": "2026-04-26T08:05:00Z",
    "is_overdue": false,
    "skip_message": null,
    "created_at": "2026-04-01T00:00:00Z"
  }
]
```

> `is_overdue` — `true` if the scheduled time has passed and medicine was not taken today.  
> `skip_message` — Non-null string reminder when `is_overdue` is `true`.

---

### POST `/api/medicines/`
Add a new medicine for the current user.

**Auth required:** Yes

**Request body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | Yes | Max 100 chars |
| `scheduled_time` | time | Yes | Format: `HH:MM:SS` |
| `dosage` | string | No | e.g. `"500mg"` |
| `is_active` | boolean | No | Default: `true` |

**Request example:**
```json
{
  "name": "Amlodipine",
  "dosage": "5mg",
  "scheduled_time": "08:00:00"
}
```

**Response `201`:** Medicine object (same shape as GET list item)

---

### GET `/api/medicines/{id}/`
Get a single medicine.

**Auth required:** Yes

**Response `200`:** Medicine object

---

### PUT / PATCH `/api/medicines/{id}/`
Update a medicine.

**Auth required:** Yes

**Request body:** Same fields as POST (all optional for PATCH)

**Response `200`:** Updated medicine object

---

### DELETE `/api/medicines/{id}/`
Delete a medicine.

**Auth required:** Yes

**Response `204`:** No content

---

### PATCH `/api/medicines/{id}/take/`
Mark a medicine as taken right now (sets `last_taken_at` to current time).

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "message": "Amlodipine marked as taken.",
  "last_taken_at": "2026-04-26T08:05:00Z"
}
```

---

## Common Error Responses

| Status | Meaning |
|---|---|
| `400` | Bad request — validation error, check response body for field-level errors |
| `401` | Unauthorized — missing or invalid JWT token |
| `403` | Forbidden — authenticated but not allowed to perform this action |
| `404` | Not found — resource does not exist or is outside the user's scope |

**Validation error shape:**
```json
{
  "field_name": ["Error message."],
  "non_field_errors": ["Error message."]
}
```

---

## Mood Values Reference

| Value | Display |
|---|---|
| `sad` | Sad |
| `happy` | Happy |
| `excited` | Excited |
| `crying` | Crying |
| `angry` | Angry |

---

## Typical Frontend Flows

### New user onboarding
1. `POST /api/auth/register/` — create account
2. `POST /api/auth/login/` — get tokens
3. `POST /api/families/{id}/join/` — join family (get family ID from a family member)

### Returning user
1. `POST /api/auth/login/` — get tokens
2. `GET /api/users/me/` — load profile + check `family.id`
3. `GET /api/families/{family.id}/` — load family dashboard

### Access token expired
1. `POST /api/auth/token/refresh/` — use refresh token to get new access token
