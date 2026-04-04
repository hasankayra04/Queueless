# QueueLess

Our mission is to provide a cost-effective and agile system that prioritizes customer satisfaction. By integrating technology into daily workflows, we aim to reduce expenses and save time for both owners and customers.

## Key Features

- **Online Queue Registration** — Customers can join a line from their mobile devices without being physically present.
- **Real-time Position Tracking** — Users can see their exact place in the queue and estimated waiting times.
- **Smart Inventory Management** — Business owners can track stock levels (e.g., baklava, churros) and set items as "out-of-stock" manually or automatically.
- **VIP & Urgent Prioritization** — Owners can prioritize specific cases to handle urgent or VIP customers first.
- **Secure Authentication** — User data is protected through JWT-based authentication with password hashing.

## Architecture

We follow a **Layered Architecture** to ensure clear separation between the User Interface, Business Logic, and Data layers.

- **Event-Driven Approach** — The system uses an `EventBus` to handle asynchronous interactions, such as updating the queue UI the moment a new customer joins.
- **Observer Pattern** — The `QueueManager` acts as the Subject that automatically notifies all `QueueObserver` objects when the queue order changes.

## Technical Details

- **Frontend:** Flutter (Web & Mobile) — `app/`
- **Backend:** Dart (Shelf HTTP server) — `backend/`
- **Patterns:** Observer Pattern, Event Bus, Provider (for Flutter state management)
- **Auth:** JWT tokens with SHA-256 password hashing

## Project Structure

```
├── backend/                  # Dart backend server
│   ├── bin/server.dart       # Server entry point
│   ├── lib/
│   │   ├── core/             # Event Bus, Observer pattern
│   │   ├── models/           # User, QueueEntry, InventoryItem
│   │   ├── services/         # AuthService, QueueManager, InventoryService
│   │   ├── routes/           # REST API route handlers
│   │   └── middleware/       # Auth middleware
│   └── test/                 # Unit tests (45 tests)
│
├── app/                      # Flutter frontend application
│   ├── lib/
│   │   ├── main.dart         # App entry point with Provider setup
│   │   ├── core/             # Client-side event bus
│   │   ├── models/           # Data models
│   │   ├── services/         # API client, auth, queue, inventory services
│   │   ├── screens/          # Login, Register, Customer Home, Owner Dashboard, Inventory
│   │   └── widgets/          # Reusable UI components
│   └── test/
```

## Getting Started

### Backend

```bash
cd backend
dart pub get
dart run bin/server.dart
```

The server starts on `http://localhost:8080`.

### Frontend

```bash
cd app
flutter pub get
flutter run
```

### Running Tests

```bash
cd backend
dart test
```

## API Endpoints

| Method | Endpoint                          | Auth | Description                     |
| ------ | --------------------------------- | ---- | ------------------------------- |
| POST   | `/api/auth/register`              | No   | Register a new user             |
| POST   | `/api/auth/login`                 | No   | Login and receive JWT token     |
| GET    | `/api/auth/me`                    | Yes  | Get current user info           |
| GET    | `/api/queue/`                     | Yes  | Get current queue               |
| POST   | `/api/queue/join`                 | Yes  | Join the queue                  |
| DELETE | `/api/queue/:id`                  | Yes  | Leave the queue                 |
| GET    | `/api/queue/position/:customerId` | Yes  | Get customer's position         |
| POST   | `/api/queue/serve-next`           | Yes  | Serve next customer             |
| POST   | `/api/queue/:id/complete`         | Yes  | Mark service as completed       |
| PUT    | `/api/queue/:id/priority`         | Yes  | Change entry priority           |
| GET    | `/api/inventory/`                 | Yes  | Get all inventory items         |
| POST   | `/api/inventory/`                 | Yes  | Add a new inventory item        |
| PUT    | `/api/inventory/:id`              | Yes  | Update an inventory item        |
| PUT    | `/api/inventory/:id/stock`        | Yes  | Update stock quantity           |
| PUT    | `/api/inventory/:id/out-of-stock` | Yes  | Set out-of-stock status         |
| DELETE | `/api/inventory/:id`              | Yes  | Remove an inventory item        |
| GET    | `/health`                         | No   | Health check                    |  
