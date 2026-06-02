# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
EventHub is a full-stack event ticket booking platform built for QA training. Users browse events, book tickets, manage bookings, and create events — each in a fully isolated sandbox.

## Tech Stack
- **Frontend**: Next.js 14 (App Router), React 18, TypeScript, Tailwind CSS, React Query v5
- **Backend**: Express.js, Prisma ORM, MySQL 8+
- **Auth**: JWT (7-day expiry), bcryptjs
- **Testing**: Playwright E2E (Chromium only), runs against `https://eventhub.rahulshettyacademy.com`

## Commands

```bash
npm run setup        # First-time install — npm install in both /backend and /frontend
npm run dev          # Start frontend (3000) + backend (3001) concurrently
npm run db:push      # Push Prisma schema to DB (non-interactive, no migration files)
npm run migrate      # prisma migrate dev (interactive, creates migration files)
npm run seed         # Seed 10 static events

npm run test         # Run all Playwright tests
npm run test:ui      # Playwright with UI mode
npm run test:report  # Open last HTML report
npx playwright test tests/<file>.spec.js --reporter=line  # Run single test file
```

## Environment Setup

**backend/.env**
```
DATABASE_URL="mysql://root:your_password@localhost:3306/eventhub"
PORT=3001
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

**frontend/.env.local**
```
NEXT_PUBLIC_API_URL=http://localhost:3001/api
```

## Architecture

Backend: Routes → Controllers → Services → Repositories → Prisma

Key files:
- `backend/app.js` — Express setup (CORS, routes, Swagger)
- `backend/src/utils/errors.js` — Domain errors (`NotFoundError`, `ForbiddenError`, `ValidationError`, `InsufficientSeatsError`) — `errorHandler.js` maps these to HTTP status codes
- `frontend/lib/api/client.ts` — Axios instance with auth interceptors (attaches Bearer token)
- `frontend/lib/providers.jsx` — React Query + Toast context providers

API base: `http://localhost:3001/api` — Swagger UI at `http://localhost:3001/api/docs`

Auth: all `/api/events` and `/api/bookings` routes require `Authorization: Bearer <token>`. Only `/api/auth/register` and `/api/auth/login` are public.

## Key Business Rules

- **Event limits**: max 6 user-created events; oldest is FIFO-deleted on overflow
- **Booking limits**: max 9 bookings per user; oldest is FIFO-deleted on overflow
- **Booking ref format**: `<EventTitle[0].toUpperCase()>-XXXXXX` (6 uppercase alphanumeric chars), e.g. `T-A3B2C1` for an event starting with "T"
- **availableSeats is per-user**: the API subtracts the requesting user's already-booked quantity from `availableSeats` before returning it — a user can never double-count seats they already hold
- **Seat atomicity**: booking decrements `availableSeats`; cancellation increments it back — both in a single Prisma transaction
- **Booking cancellation** is a permanent DELETE, not a status change
- **Static events** (`isStatic: true`) are the 10 seeded events — they cannot be updated or deleted
- **Cross-user access**: fetching another user's booking returns 403 "Access Denied"
- **Refund eligibility**: quantity = 1 → eligible; quantity > 1 → not eligible (client-side logic only)

## Testing Conventions

- Test files: `tests/<feature-name>.spec.js`
- Test accounts: `rahulshetty1@gmail.com` / `Magiclife1!`
- Tests are self-contained: login → clear state → action → assert
- Locator priority: `data-testid` > role > label/placeholder > ID > CSS class
- No `page.waitForTimeout()` — use `expect(...).toBeVisible()`
- `baseURL` is `https://eventhub.rahulshettyacademy.com` (set in `playwright.config.ts`)

### data-testid Reference

| `data-testid` | Element |
|---|---|
| `event-card` | Event card in listings |
| `book-now-btn` | "Book Now" link on event card |
| `quantity-input` | Ticket quantity in booking form |
| `customer-name` | Full name input |
| `customer-email` | Email input |
| `customer-phone` | Phone number input |
| `confirm-booking-btn` | Submit booking button |
| `booking-ref` | Reference shown on confirmation |
| `booking-card` | Booking card in my bookings list |
| `cancel-booking-btn` | Cancel booking button |
| `confirm-dialog-yes` | Confirm button in dialogs |
| `admin-event-form` | Admin event create/edit form |
| `event-title-input` | Title field in admin form |
| `add-event-btn` | Submit in admin form |
| `event-table-row` | Row in admin events table |
| `edit-event-btn` | Edit button in admin table row |
| `delete-event-btn` | Delete button in admin table row |
| `nav-events` | Navbar "Events" link |
| `nav-bookings` | Navbar "My Bookings" link |

## Custom Slash Commands (Agents)

- `/generate-tests <feature>` — AI Test Automation Engineer: generates Playwright tests
- `/review-tests <file>` — AI Code Reviewer: reviews test code quality
- `/create-scenarios <area>` — AI Functional Tester: creates test scenario documents
- `/test-strategy <scenarios>` — AI Test Architect: assigns tests to optimal pyramid layers

## Skill Documents

- `.claude/docs/playwright-best-practices.md` — Playwright testing standards
- `.claude/docs/eventhub-domain.md` — Domain knowledge and business rules

## Code Style

- Backend: JavaScript with JSDoc, Express patterns
- Frontend: TypeScript, React hooks, Tailwind utility classes
- Tests: JavaScript with Playwright test runner
- Add step comments in tests; keep functions focused and single-responsibility
