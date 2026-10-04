# Smart Inventory System (Flutter + Node.js + PostgreSQL)

```
inventory-system/
├── backend/    Node.js + Express REST API, JWT auth, PostgreSQL
└── frontend/   Flutter app (Android, iOS, Web) - 15 pages
```

## 1. Install tools
| Tool | Why | Link |
|---|---|---|
| Git | version control | https://git-scm.com |
| Node.js 20 LTS | runs the API | https://nodejs.org |
| PostgreSQL 16 | database (remember the postgres password) | https://www.postgresql.org/download |
| Flutter SDK 3.27+ | app (run `flutter doctor`) | https://docs.flutter.dev/get-started/install |
| VS Code + Flutter/Dart extensions | editor | https://code.visualstudio.com |
| Android Studio (emulator) | Android testing | https://developer.android.com/studio |

## 2. Run the backend
```bash
cd backend
npm install
cp .env.example .env        # Windows: copy .env.example .env
# edit .env -> set DATABASE_URL password and a long JWT_SECRET
```
Create the database once (psql or pgAdmin):
```sql
CREATE DATABASE smart_inventory;
```
Then:
```bash
npm run db:init   # creates tables, sample data, admin user
npm run dev       # API on http://localhost:4000/api/health
```
Default login: `admin@inventory.com` / `Admin@123` (change it in Profile).

## 3. Run the Flutter app
```bash
cd frontend
flutter create . --platforms=android,ios,web   # generates platform folders (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run -d chrome                           # web
flutter run                                     # Android emulator / connected phone
```
- Android emulator reaches your PC at `10.0.2.2` (already handled).
- Real phone: `flutter run --dart-define=API_URL=http://YOUR_PC_IP:4000/api`

## 4. API summary (all except /auth/register & /auth/login need `Authorization: Bearer <token>`)
| Method | Path | Purpose |
|---|---|---|
| POST | /api/auth/register, /api/auth/login | sign up / sign in |
| GET/PUT | /api/auth/me | read / update profile |
| PUT | /api/auth/me/password | change password |
| GET/POST/PUT/DELETE | /api/products (?search=&category_id=&low=true) | products |
| GET/POST/PUT/DELETE | /api/categories, /api/suppliers | master data |
| GET/POST | /api/movements | stock in / out / adjust (transactional) |
| GET | /api/dashboard, /api/reports/stock-by-category | summary and reports |
| GET/PUT/DELETE | /api/users (admin only) | team management |

## 5. Push to GitHub
```bash
cd inventory-system
git init
git add .
git commit -m "Initial commit: smart inventory system"
git branch -M main
# create an EMPTY repo on github.com (New repository), then:
git remote add origin https://github.com/YOUR_USERNAME/smart-inventory.git
git push -u origin main
```
Later updates: `git add . && git commit -m "message" && git push`.
Never commit `.env` (already in .gitignore).

## 6. Deploy online (free tiers)
**Database + API on Render (https://render.com)**
1. New > PostgreSQL > create; copy the *External Database URL*.
2. New > Web Service > connect your GitHub repo. Root Directory: `backend`. Build: `npm install`. Start: `npm start`.
3. Environment variables: `DATABASE_URL` (the URL above), `JWT_SECRET` (long random), `DB_SSL=true`.
4. Once, from your PC with that URL in `backend/.env`: `npm run db:init` to create tables.
5. API lives at `https://YOUR-SERVICE.onrender.com/api`.

**Flutter web on GitHub Pages**
```bash
cd frontend
flutter build web --release --base-href "/smart-inventory/" --dart-define=API_URL=https://YOUR-SERVICE.onrender.com/api
```
Push the contents of `frontend/build/web` to a `gh-pages` branch (or use the `peaceiris/actions-gh-pages` GitHub Action), then
Repo > Settings > Pages > Branch `gh-pages`.

**Android APK**: `flutter build apk --release --dart-define=API_URL=https://YOUR-SERVICE.onrender.com/api` -> `build/app/outputs/flutter-apk/app-release.apk`.

## 7. Pages (15)
Splash, Login, Register, Dashboard, Products, Product Detail, Add/Edit Product, Categories, Suppliers, Stock In/Out, Stock History, Low Stock Alerts, Reports, Profile, Settings.
