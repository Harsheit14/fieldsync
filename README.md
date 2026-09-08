FieldSync

Professional README

Offline-first Flutter field survey application demonstrating reliable mobile data synchronization under unreliable network conditions.

Table of Contents

Overview

Problem

Core Design Principles

Architecture

Offline-First Data Flow

Outbox Pattern

Synchronization Engine

Retry and Backoff

Conflict Handling

Idempotency

Delete Synchronization

Background Synchronization

Local File Persistence

Backend Architecture

Technology Stack

Project Structure

Testing

Running the Project

Example Synchronization Scenario

Design Decisions

Trade-offs and Limitations

What This Project Demonstrates

Future Extensions

Key Takeaway

License

Overview

FieldSync is a reference implementation of an offline-first mobile architecture built with Flutter.

The project focuses on a common mobile systems problem:

How do you build an application that remains usable when the network is slow, unavailable, or unreliable, while still synchronizing local changes safely with a remote backend?

Instead of making the network the center of the application, FieldSync treats the local database as the source of truth and performs synchronization asynchronously through a durable operation queue.

The project is intentionally focused on demonstrating mobile architecture, persistence, synchronization, reliability, and system design, rather than building a large production business platform.

The Central Principle

The user should be able to work regardless of network availability.

User Action
     ↓
Local Database
     ↓
UI updates immediately
     ↓
Durable Pending Operation
     ↓
Synchronization Engine
     ↓
Remote Backend

The network becomes a synchronization mechanism rather than a prerequisite for using the application.

Problem

Traditional mobile CRUD applications often follow this model:

User
  ↓
API
  ↓
Server
  ↓
Response
  ↓
UI

This works well when connectivity is reliable.

It becomes problematic in real-world mobile environments.

A field survey officer may be working:

Without network coverage

With intermittent connectivity

With high latency

During temporary server outages

While switching between Wi-Fi and cellular networks

A network-dependent application can make a simple operation such as creating a survey fail completely.

FieldSync addresses this by separating local application state from remote synchronization state.

The application can therefore continue operating locally even when the backend is unavailable.

Core Design Principles

1. Local database is the source of truth

The UI reads survey data from SQLite through Drift. The UI does not depend directly on the network to display the current state.

2. Network availability does not block user actions

A survey can be created, edited, or deleted while offline.

3. Mutations become durable operations

Every synchronization-relevant mutation produces a pending operation.

4. Synchronization is independent of the UI

The synchronization engine operates independently of screens and widgets.

5. Operations are idempotent

Each synchronization operation has a unique operation ID. The backend uses that ID to prevent duplicate processing.

6. Failed operations are retryable

Temporary failures do not immediately destroy the user's work. Operations remain persisted until they succeed or are classified as permanently failed.

7. Conflicts are explicitly handled

The backend validates timestamps and rejects stale mutations rather than blindly overwriting newer data.

8. File references are portable

Application-specific absolute paths are not persisted as durable identifiers. Photo references are stored relative to the application's storage root.

Architecture

FieldSync uses a layered architecture with clear separation between presentation, domain logic, persistence, and synchronization.

┌──────────────────────────────────────────┐
│              Presentation                │
│  Flutter Widgets                         │
│  Riverpod Notifiers / Providers          │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│                 Domain                   │
│  Use Cases                               │
│  Repository Interfaces                  │
│  Domain Entities                         │
│  Validation                              │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│                  Data                    │
│  Repository Implementations             │
│  Mappers                                │
│  DAOs                                   │
│  Remote Services                        │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│            Local Persistence             │
│              Drift / SQLite              │
└──────────────────────────────────────────┘

Synchronization is implemented as a separate subsystem:

                    ┌──────────────────┐
                    │   Connectivity   │
                    │     Service      │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ Sync Coordinator │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ Synchronization  │
                    │     Service      │
                    └────────┬─────────┘
                             │
                    ┌────────┴─────────┐
                    ▼                  ▼
          ┌──────────────────┐  ┌───────────────┐
          │ Pending Operation│  │  Retry Policy │
          │   Repository     │  │               │
          └────────┬─────────┘  └───────────────┘
                   │
                   ▼
          ┌──────────────────┐
          │  Sync Handlers   │
          └────────┬─────────┘
                   │
                   ▼
          ┌──────────────────┐
          │  Remote Sync API │
          └────────┬─────────┘
                   │
                   ▼
          ┌──────────────────┐
          │   PostgreSQL     │
          └──────────────────┘

Offline-First Data Flow

Consider creating a survey while the device has no connectivity.

User creates survey
        │
        ▼
CreateSurveyNotifier
        │
        ▼
CreateSurveyUseCase
        │
        ▼
SurveyRepository
        │
        ├───────────────┐
        ▼               ▼
   Survey table    Pending Operations
        │               │
        ▼               ▼
     SQLite          SQLite
        │
        ▼
   UI updates

No network request is required to complete the user's action.

Later, when connectivity becomes available:

Connectivity restored
        │
        ▼
Sync Coordinator
        │
        ▼
Synchronization Service
        │
        ▼
Pending Operation
        │
        ▼
Remote Sync Service
        │
        ▼
POST /api/sync
        │
        ▼
Backend
        │
        ▼
PostgreSQL
        │
        ▼
Operation marked completed

Outbox Pattern

FieldSync uses the Outbox Pattern to make synchronization durable.

Instead of immediately depending on a network request, the application records the mutation as an operation in the local database.

operationId
entityType
entityId
operationType
payload
createdAt
retryCount
status
nextRetryAt
errorMessage

Example:

{
  "operationId": "operation-123",
  "entityType": "Survey",
  "entityId": "survey-456",
  "operationType": "update",
  "payload": {
    "farmerName": "Ada Farmer",
    "cropType": "Wheat"
  }
}

The operation remains durable until the synchronization system successfully processes it.

This means an application restart does not automatically lose unsynchronized work.

Synchronization Engine

The synchronization system is intentionally separated from the UI.

Connectivity Service

Determines whether network connectivity is currently available.

Sync Coordinator

Controls when synchronization should happen. It reacts to connectivity changes, newly queued operations, retry scheduling, and application lifecycle events.

Synchronization Service

Executes one synchronization cycle: retrieves ready operations, finds a handler, processes the operation, applies the result, schedules retries when appropriate, and marks permanent failures.

Sync Handler

Provides entity-specific synchronization behavior. The current implementation includes SurveySyncHandler for Survey create, update, and delete operations.

Retry and Backoff

Not every synchronization failure should be treated equally. FieldSync distinguishes between temporary and permanent failures.

Retryable failures

Network unavailable

Connection timeout

Server-side 5xx error

Permanent failures

Invalid request

Unsupported operation

Entity not found

Synchronization conflict

The retry policy uses exponential backoff.

Attempt 1 → short delay
Attempt 2 → longer delay
Attempt 3 → longer delay
Attempt 4 → longer delay
...

This prevents repeatedly hammering an unavailable backend.

Conflict Handling

Offline applications can create stale updates.

Device A
   │
   ├── updates Survey
   │
   └── remains offline


Device B
   │
   ├── updates same Survey
   │
   └── synchronizes first

When Device A eventually reconnects, its update may be older than the version already stored on the server.

FieldSync uses timestamps to detect this.

incoming.updatedAt
        vs
existing.updatedAt

If the incoming mutation is stale, the backend returns a synchronization conflict instead of overwriting newer server data.

This makes synchronization behavior explicit rather than relying on accidental last-write-wins behavior.

Idempotency

Mobile networks can produce uncertain request outcomes.

Client → Server
        │
        │ operation processed
        │
        X response lost

The client may retry the same operation. Without idempotency, the server could process it twice.

FieldSync assigns every pending operation a unique operationId.

operation-123
      │
      ├── first request → processed
      │
      └── retry         → recognized as duplicate

This is especially important for reliable mobile synchronization.

Delete Synchronization

Deletes are treated as synchronization operations rather than simply removing the local row.

operationType = delete

The backend uses a soft-delete strategy. This preserves synchronization semantics while preventing deleted entities from being returned as active records.

The delete operation also carries its updated timestamp so that stale deletes can be rejected.

Background Synchronization

Foreground synchronization should not be the only synchronization mechanism.

FieldSync also integrates background execution through WorkManager.

                 ┌─────────────────┐
                 │ Foreground App  │
                 └────────┬────────┘
                          │
                          ▼
                SynchronizationService
                          ▲
                          │
                 ┌────────┴────────┐
                 │ Background Task│
                 └─────────────────┘

The background worker creates the synchronization dependencies independently and invokes the same domain-level synchronization service used by foreground synchronization.

This avoids duplicating synchronization logic between foreground and background execution.

The iOS implementation also registers the background task with the native WorkManager integration.

Local File Persistence

Survey photos are stored locally because the application must remain usable offline.

Documents/
└── FieldSync/
    └── surveys/
        └── images/
            └── survey_<uuid>.jpg

The database stores a relative reference:

surveys/images/survey_<uuid>.jpg

rather than an absolute application-container path.

This is important because mobile application containers can change between installations or application lifecycle events.

When the file is needed, the storage service resolves:

Application Documents Directory
        +
FieldSync
        +
stored relative reference

This keeps the persisted reference independent of the current application container path.

Legacy absolute paths are also recognized by the storage service for compatibility with previously stored records.

Backend Architecture

The backend is implemented as a small TypeScript service using Express and PostgreSQL.

HTTP Request
     │
     ▼
Controller
     │
     ▼
Validation / Schema
     │
     ▼
Sync Service
     │
     ├───────────────┐
     ▼               ▼
Survey Repository   Sync Operation Repository
     │               │
     └───────┬───────┘
             ▼
         PostgreSQL

The main synchronization endpoint is:

POST /api/sync

The backend validates:

Operation ID

Entity type

Entity ID

Operation type

Survey payload

Coordinates

Timestamps

It then executes the synchronization inside a database transaction.

Transactional Synchronization

The backend processes synchronization operations transactionally.

BEGIN TRANSACTION

    Insert / validate operation

            ↓

    Apply business mutation

            ↓

    Mark operation completed

COMMIT

If an unexpected failure occurs:

ROLLBACK

This prevents partially applied synchronization operations.

Technology Stack

Mobile

Flutter

Dart

Riverpod

Drift

SQLite

Dio

WorkManager

Connectivity Plus

Camera / Image Picker

Path Provider

UUID

Backend

Node.js

TypeScript

Express

PostgreSQL

Zod

Supertest

node:test

tsx

Architecture & Patterns

Offline-First Architecture

Repository Pattern

Outbox Pattern

Operation-Based Synchronization

Dependency Injection

Layered Architecture

Exponential Backoff

Idempotent APIs

Optimistic Local Updates

Transactional Backend Processing

Project Structure

fieldsync/
│
├── lib/
│   ├── app/
│   │   ├── router/
│   │   └── theme/
│   ├── core/
│   │   ├── config/
│   │   ├── database/
│   │   ├── errors/
│   │   ├── logger/
│   │   ├── network/
│   │   └── providers/
│   └── features/
│       ├── camera/
│       ├── dashboard/
│       ├── developer/
│       ├── location/
│       ├── storage/
│       ├── survey/
│       └── sync/
│
├── backend/
│   └── src/
│       ├── config/
│       ├── controllers/
│       ├── repositories/
│       ├── routes/
│       ├── schemas/
│       └── services/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
├── web/
├── pubspec.yaml
└── README.md

Testing

Testing is an important part of the project because synchronization behavior is difficult to reason about through UI testing alone.

Unit Tests

Survey validation

Repositories

Use cases

Retry policy

Remote synchronization service

Sync handlers

Synchronization service

Sync coordinator

Background sync runner

Metrics

Logging

Widget Tests

Survey card actions

Delete flows

Edit/delete menu behavior

Integration Tests

Complete synchronization scenarios are tested, including:

Create locally
     ↓
Pending operation
     ↓
Backend synchronization
     ↓
Database verification

Offline
  ↓
Create / Update / Delete
  ↓
Reconnect
  ↓
Retry
  ↓
Backend
  ↓
PostgreSQL

Validation

Run the complete Flutter test suite:

flutter test

Run static analysis:

flutter analyze

Backend TypeScript compilation:

cd backend
npx tsc --noEmit

Running the Project

Prerequisites

Flutter SDK

Dart SDK

Xcode for iOS/macOS development

Android Studio / Android SDK for Android development

Node.js

PostgreSQL

Clone the Repository

git clone https://github.com/Harsheit14/fieldsync.git
cd fieldsync

Flutter Setup

flutter pub get

Backend Setup

cd backend
npm install

Configure the PostgreSQL connection using the backend environment configuration.

Start the backend:

npm run dev

The API will run on the configured backend port.

Run the Flutter Application

flutter run

For iOS:

flutter run -d ios

For Android:

flutter run -d android

Example Synchronization Scenario

Consider a survey officer working without connectivity.

Step 1 — Create Survey

Farmer: Ada Farmer
Crop: Wheat
Area: 12.5

The survey is immediately stored locally.

SQLite
└── Survey

A pending operation is also created:

CREATE Survey

Step 2 — Device Remains Offline

The UI continues to display the survey.

PENDING

Step 3 — Connectivity Returns

Connectivity
     ↓
Sync Coordinator
     ↓
Synchronization Service

Step 4 — Operation Is Uploaded

POST /api/sync

Step 5 — Backend Processes It

Validates the request.

Checks operation idempotency.

Applies the survey mutation.

Marks the operation completed.

Commits the transaction.

Step 6 — Local Operation Completes

PENDING
   ↓
COMPLETED

The user never needed to manually press a "Sync" button.

Design Decisions

Why SQLite as the Source of Truth?

Because the application must remain useful without connectivity. If the UI depended on server responses, offline behavior would become difficult to guarantee. SQLite therefore acts as the local source of truth.

Why an Outbox?

A network request is not a durable storage mechanism. The synchronization operation needs to survive network failure, application restart, process termination, and temporary server failure. Persisting the operation locally solves this.

Why Operation IDs?

Retries can produce duplicate requests. An operation ID gives the backend a stable identity for a synchronization operation. This makes synchronization idempotent.

Why Separate SyncCoordinator and SynchronizationService?

The coordinator controls when synchronization happens. The synchronization service controls how one synchronization cycle is executed. This allows foreground and background execution to share synchronization logic without coupling the worker to application lifecycle behavior.

Why Use SyncHandlers?

Synchronization logic should not become a large conditional block. Entity-specific handlers can process their own operations, allowing the synchronization engine to remain generic and extensible.

Why Store Relative Photo Paths?

Application container paths are not stable identifiers. A relative reference such as surveys/images/survey_123.jpg allows the storage layer to resolve the current location dynamically.

Trade-offs and Limitations

FieldSync intentionally focuses on the core mechanics of offline-first synchronization.

It does not attempt to implement every concern required by a commercial production application.

For example, the reference implementation does not focus on:

Authentication and authorization

Large-scale multi-tenant infrastructure

Advanced server-side conflict resolution

Distributed backend infrastructure

Cloud deployment

CI/CD pipelines

Production observability

Push notifications

Large-scale media upload infrastructure

Resumable uploads

Comprehensive device-farm testing

These are outside the primary scope of the project.

The goal is to demonstrate the architecture and reasoning required to build a reliable offline-first mobile application.

What This Project Demonstrates

FieldSync demonstrates practical understanding of mobile system design.

Mobile Architecture

Layered architecture

Repository pattern

Dependency inversion

Domain/data/presentation separation

Dependency injection

Offline-First Design

Local source of truth

Optimistic local updates

Durable local mutations

Offline operation

Synchronization

Outbox pattern

Operation-based synchronization

Retry handling

Exponential backoff

Idempotency

Conflict detection

Transactional backend processing

Mobile Platform Concerns

Connectivity changes

Background execution

Application lifecycle

Local file persistence

Portable storage references

Software Engineering

Unit testing

Widget testing

Integration testing

Backend testing

Separation of concerns

Explicit failure handling

Future Extensions

Multi-device synchronization

More sophisticated conflict-resolution strategies

Tombstone/version-vector based synchronization

Incremental synchronization

Delta synchronization

Server-issued entity versions

Authentication and authorization

Encrypted local storage

Large media upload queues

Resumable uploads

Push-triggered synchronization

More advanced background scheduling

Synchronization protocol versioning

Performance profiling with large local datasets

These are intentionally outside the current scope.

Key Takeaway

Connectivity should affect synchronization timing, not whether the user can work.

The device owns the immediate local state.

The outbox records what needs to reach the server.

The synchronization engine determines when and how operations are delivered.

The backend provides idempotency, validation, transactional persistence, and conflict protection.

Together, these components create a mobile system that remains useful under unreliable connectivity while maintaining a clear and reliable synchronization model.

License

This project is available under the MIT License.

See LICENSE for details.

FieldSync — Offline-First Mobile Architecture
