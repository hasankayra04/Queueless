# QueueLess
Our mission is to provide a cost-effective and agile system that prioritizes customer satisfaction. By integrating technology into daily workflows, 
we aim to reduce expenses and save time for both owners and customers.  

Key Features:  
-> Online Queue Registration: Customers can join a line from their mobile devices without being physically present.  
-> Real-time Position Tracking: Users can see their exact place in the queue and estimated waiting times.  
-> Smart Inventory Management: Business owners can track stock levels (e.g., baklava, churros) and set items as "out-of-stock" manually or automatically.  
-> VIP & Urgent Prioritization: Owners can prioritize specific cases to handle urgent or VIP customers first.  
-> Secure Authentication: User data is protected through a secure login mechanism.  

Architecture:  
&nbsp;&nbsp;&nbsp;&nbsp;We followed a Layered Architecture to ensure a clear separation between the User Interface, Business Management, and Database layers.  
-> Event-Driven Approach: The system uses an "Event Bus" to handle asynchronous interactions, such as updating the queue UI the moment a new customer joins .  
-> Design Pattern: We implemented the Observer Pattern. The QueueManager acts as the Subject that automatically notifies all Customer (Observer) objects when the queue order changes.  

Technical Details:  
-> Frontend: Flutter (Web & Mobile) — `frontend/`  
-> Backend: Dart (shelf HTTP server) — `backend/`  
-> Database: In-memory (production-ready PostgreSQL integration path available)  
-> Patterns: Observer Pattern + Event Bus (pure Dart)  

---

## Running the Application

### Backend (Dart server)

```bash
cd backend
dart pub get
dart run bin/server.dart          # starts on http://localhost:8080
# or build a native executable:
dart compile exe bin/server.dart -o queueless_server
./queueless_server
```

**Available endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/register | Register (role: customer \| businessOwner) |
| POST | /auth/login | Login → returns Bearer token |
| POST | /auth/logout | Logout (auth) |
| GET | /auth/me | Current user (auth) |
| GET | /businesses/ | List all businesses |
| POST | /businesses/ | Create business (owner auth) |
| PATCH | /businesses/:id | Update business (owner auth) |
| GET | /businesses/my | Owner's businesses (owner auth) |
| GET | /queue/:businessId | Get queue (public) |
| POST | /queue/:businessId/join | Join queue (customer auth) |
| DELETE | /queue/:businessId/leave | Leave queue (customer auth) |
| POST | /queue/:businessId/serve-next | Serve next (owner auth) |
| PATCH | /queue/:businessId/entry/:id/priority | Set priority (owner auth) |
| GET | /inventory/:businessId | List inventory (public) |
| POST | /inventory/:businessId | Add item (owner auth) |
| PATCH | /inventory/:businessId/:itemId | Update item (owner auth) |
| POST | /inventory/:businessId/:itemId/out-of-stock | Mark OOS (owner auth) |
| DELETE | /inventory/:businessId/:itemId | Delete item (owner auth) |

### Backend tests

```bash
cd backend
dart test
# 24 tests — all passing
```

### Frontend (Flutter app)

```bash
cd frontend
flutter pub get
flutter run                       # runs on connected device / browser
# for web:
flutter run -d chrome
```

> Set the `baseUrl` in `frontend/lib/main.dart` to match your backend host before building.

---

## Project Structure

```
├── backend/
│   ├── bin/server.dart           # HTTP server entry point (shelf)
│   ├── lib/
│   │   ├── models/               # User, Business, QueueEntry, InventoryItem
│   │   ├── patterns/
│   │   │   ├── observer.dart     # QueueObserver / QueueSubject interfaces
│   │   │   └── event_bus.dart    # Singleton async event bus
│   │   ├── services/
│   │   │   ├── queue_manager.dart    # Observer Subject — manages all queues
│   │   │   ├── auth_service.dart     # Registration, login, session tokens
│   │   │   ├── business_service.dart # Business CRUD
│   │   │   └── inventory_service.dart# Stock management
│   │   ├── api/
│   │   │   ├── middleware.dart   # Response helpers, optional-auth middleware
│   │   │   └── handlers/        # auth, business, queue, inventory
│   │   └── database/
│   │       └── in_memory_db.dart # In-memory data store
│   └── test/queueless_test.dart  # 24 unit + integration tests
│
└── frontend/
    └── lib/
        ├── main.dart             # App entry, provider setup, root navigation
        ├── models/models.dart    # Frontend data models (JSON deserialization)
        ├── services/
        │   ├── api_service.dart  # HTTP client for all backend endpoints
        │   └── providers.dart    # ChangeNotifier state (Auth, Business, Queue, Inventory)
        └── screens/
            ├── auth/             # Login & Register screens
            ├── customer/         # Business browser, queue join/leave/track
            └── owner/            # Business management, queue control, inventory
```
  
