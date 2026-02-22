# Kumi Labs

A Blinkit-like B2C quick commerce application built for a time-boxed internship assignment. It is **not** a production system.

**Stack:** Python (FastAPI), Flutter, MongoDB, Docker, Kubernetes.

---

## Architecture overview

The system is split into four backend microservices and one mobile client:

```
                    +------------------+
                    |  Flutter app     |
                    |  (B2C client)   |
                    +--------+--------+
                             |
         +-------------------+-------------------+
         |                   |                   |
    +----v----+        +-----v-----+        +-----v-----+
    | Users  |        |  Catalog  |        |  Orders   |
    | :8000  |        |  :8001    |        |  :8002    |
    +----+---+        +-----+-----+        +-----+-----+
         |                   |                   |
         |              +----v----+               |
         |              |Delivery |               |
         |              | :8003   |               |
         |              +----+----+               |
         |                   |                   |
         +-------------------+-------------------+
                             |
                    +--------v--------+
                    |    MongoDB      |
                    |    :27017      |
                    +-----------------+
```

- There is **no API gateway**: the Flutter app talks directly to each service.
- Every service has its own MongoDB database (or DB name); there is no shared schema.
- Services do not call each other except for the app: after creating an order it calls the Delivery service to set initial status to `PLACED`.

---

## Service responsibilities

| Service | Port | Responsibility |
|--------|------|----------------|
| **Users** | 8000 | Registration, login (JWT), profile. Password hashing (bcrypt). Hardcoded OTP `1234` for optional OTP login. |
| **Catalog** | 8001 | Product catalog and categories. Read-only for the client; products are pre-seeded via script. |
| **Orders** | 8002 | Cart (add/remove, get) and orders (create, list). Identifies the user via `X-User-Id` header. Orders are assumed prepaid; no payment logic. |
| **Delivery** | 8003 | Order status per order: get status and manual status updates. Status flow: `PLACED` → `PACKED` → `OUT_FOR_DELIVERY` → `DELIVERED`. |

---

## API list

### Users (no auth unless noted)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness/readiness |
| POST | `/register` | Register; body: `email`, `password`, `name`. Returns JWT. |
| POST | `/login` | Login; body: `email`, `password` (or `otp` = `1234`). Returns JWT. |
| GET | `/profile` | Profile (Bearer JWT required); returns `email`, `name`. |

### Catalog

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness/readiness |
| GET | `/products` | List all products |
| GET | `/products/{product_id}` | Get one product |
| GET | `/categories` | List distinct categories |

### Orders (all require header `X-User-Id`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness/readiness |
| GET | `/cart` | Get current cart |
| POST | `/cart/add` | Add item; body: `product_id`, `quantity` (default 1) |
| POST | `/cart/remove` | Remove item; body: `product_id` |
| POST | `/order/create` | Create order from cart; body: `total`. Returns order ref and timestamp. |
| GET | `/orders` | List orders for the user |

### Delivery

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness/readiness |
| GET | `/order/{order_id}/status` | Get status for an order |
| POST | `/order/{order_id}/update-status` | Update status; body: `status` (PLACED, PACKED, OUT_FOR_DELIVERY, DELIVERED) |

---

## Local setup instructions

### Prerequisites

- Python 3.11+, MongoDB (running locally or reachable), Flutter SDK (for the app)
- Docker and Docker Compose (optional, see below)
- For Kubernetes: Minikube or Kind

### Backend (without Docker)

1. **MongoDB**  
   Start MongoDB on `localhost:27017` (or set the corresponding `*_MONGODB_URL` env vars).

2. **Users**
   ```bash
   cd services/users && pip install -r requirements.txt && uvicorn main:app --reload
   ```
   Optional: copy `.env.example` to `.env` and set `USERS_JWT_SECRET`, etc.

3. **Catalog**
   ```bash
   cd services/catalog && pip install -r requirements.txt && python seed.py && uvicorn main:app --reload --port 8001
   ```

4. **Orders**
   ```bash
   cd services/orders && pip install -r requirements.txt && uvicorn main:app --reload --port 8002
   ```

5. **Delivery**
   ```bash
   cd services/delivery && pip install -r requirements.txt && uvicorn main:app --reload --port 8003
   ```

### Flutter app

```bash
cd app
flutter create . --project-name kumi_app   # if platform folders are missing
flutter pub get
flutter run
```

In `lib/services/api_service.dart`, base URLs use `10.0.2.2` for the Android emulator. For iOS simulator or a physical device, change them to your machine’s IP or `localhost` as appropriate.

### Demo checklist (for recording)

1. **Start backend**  
   Either run all four services + MongoDB locally (see above), or run `docker compose up --build` from the repo root.

2. **Seed catalog**  
   If using Docker:  
   `docker compose run --rm -e CATALOG_MONGODB_URL=mongodb://mongodb:27017 -e CATALOG_MONGODB_DB=catalog_db catalog python seed.py`  
   If running catalog locally: from `services/catalog` run `python seed.py` once.

3. **Start the app**  
   From `app`: `flutter run` (emulator or device). Ensure base URLs in `api_service.dart` match your environment (e.g. `10.0.2.2` for Android emulator).

4. **Suggested flow**  
   Sign up → Home (products) → Add to cart → Cart → Place order → Order confirmation → Track order. If any screen shows "Cannot reach server", check that all four services and MongoDB are running.

---

## Docker and Kubernetes notes

### Docker Compose (local dev)

From the repository root:

```bash
docker compose up --build
```

- **MongoDB:** `localhost:27017`
- **Users:** http://localhost:8000
- **Catalog:** http://localhost:8001
- **Orders:** http://localhost:8002
- **Delivery:** http://localhost:8003

Seed the catalog once (with Compose running):

```bash
docker compose run --rm -e CATALOG_MONGODB_URL=mongodb://mongodb:27017 -e CATALOG_MONGODB_DB=catalog_db catalog python seed.py
```

Configuration is via environment variables in `docker-compose.yml`; you can override with a `.env` file in the same directory.

### Kubernetes (Minikube / Kind)

Manifests live in `k8s/`. They are intended for local clusters (Minikube or Kind) and avoid cloud-specific resources (no cloud LoadBalancer, no cloud storage).

1. **Apply manifests** (order does not strictly matter; Secret and MongoDB first is sensible):
   ```bash
   kubectl apply -f k8s/secret.yaml
   kubectl apply -f k8s/mongodb.yaml
   kubectl apply -f k8s/users.yaml
   kubectl apply -f k8s/catalog.yaml
   kubectl apply -f k8s/orders.yaml
   kubectl apply -f k8s/delivery.yaml
   ```
   Or: `kubectl apply -f k8s/`

2. **Backend images**  
   Deployments expect local images: `users-service:latest`, `catalog-service:latest`, `orders-service:latest`, `delivery-service:latest` with `imagePullPolicy: IfNotPresent`.

   **Kind:** build and load:
   ```bash
   docker build -t users-service:latest ./services/users
   docker build -t catalog-service:latest ./services/catalog
   docker build -t orders-service:latest ./services/orders
   docker build -t delivery-service:latest ./services/delivery
   kind load docker-image users-service:latest catalog-service:latest orders-service:latest delivery-service:latest
   ```

   **Minikube:** build inside the Minikube Docker env so images are available without loading:
   ```bash
   eval $(minikube docker-env)
   docker build -t users-service:latest ./services/users
   # ... same for catalog, orders, delivery
   ```

3. **MongoDB storage**  
   The MongoDB Deployment uses an `emptyDir` volume (no PersistentVolume). Data does not persist across pod restarts. Suitable for dev only.

4. **Accessing services**  
   Use `kubectl port-forward` or an Ingress if you configure one. The manifests do not define an Ingress.

---

## Assumptions made

- **User identification for cart/orders:** The Orders service uses the `X-User-Id` header. The Flutter app sends the user’s **email** (from login/register) as `X-User-Id`. There is no separate user-id from the Users service.
- **Orders are prepaid:** No payment gateway or payment flow; the client sends a `total` when creating an order.
- **Delivery status:** Manual updates only. The app sets status to `PLACED` when an order is created so tracking works; no automatic progression.
- **Single MongoDB instance:** All services can point at one MongoDB server with different database names (e.g. `users_db`, `catalog_db`, `orders_db`, `delivery_db`).
- **OTP:** A single hardcoded OTP `1234` is accepted for login where OTP is used.
- **Local / assignment use:** No production hardening (secrets, rate limiting, TLS, etc.).

---

## Known limitations

- **No API gateway:** The client must know all service URLs and handle cross-service flows (e.g. create order then set delivery status).
- **No persistent auth in the app:** Token and user id are kept in memory only; closing the app loses the session.
- **Catalog seed:** Products exist only after running `seed.py`; no admin API to add products.
- **Cart total:** Computed in the client from catalog prices; the Orders service does not validate total against catalog.
- **Order status:** No validation of status transitions (e.g. DELIVERED → PLACED is allowed).
- **Kubernetes:** No Ingress, no TLS, no persistent storage for MongoDB; images are local only.

---

## AI & Tooling Transparency

- **Tools used:** Cursor (Composer / AI-assisted editing) for most implementation work. No other AI or vibe coding tools were used for this repo.
- **AI-assisted:** Backend service scaffolding (FastAPI routes, Pydantic models, MongoDB wiring); Flutter app skeleton and screens (login, signup, home, cart, order confirmation, order tracking); `api_service.dart` and API boilerplate; Dockerfiles, `docker-compose.yml`, and Kubernetes manifests; README structure and setup/API docs. Requirements and constraints (e.g. four microservices, no gateway, minimal scope) were supplied by the author; structure and code were generated to match.
- **Manual:** Requirements and scope definition; design choices (ports, header-based user id, status flow); integration and wiring (e.g. app calling Delivery after creating an order); error handling and UX details (SnackBars, loading states, button disabling); seed script and demo flow; review, testing, and edits to generated code.
- **Intent:** This section is for transparency. The project uses only standard, open-source dependencies; setup and behaviour are documented so the system can be run and modified without relying on undocumented AI context.
