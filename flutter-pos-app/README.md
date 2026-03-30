# FlutterPOS - Offline POS Android App

A complete offline Point of Sale (POS) Android application built with Flutter, SQLite, Provider state management, and Bluetooth thermal printer support.

---

## Features

- **Login System** — Admin and Cashier roles (default: `admin` / `admin123`)
- **Store Setup** — Name, address, phone, GST number, store logo
- **Dashboard** — Today's sales, total orders, quick action buttons
- **Products** — Full CRUD with image, barcode, category, cost/selling price, tax, stock
- **Customers** — Full CRUD with name, phone, email, address
- **Billing Screen** — POS layout with product grid, search, cart, live calculations, checkout
- **Payment Methods** — Cash, UPI, Card
- **Estimations** — Create quotations, print, convert to sale
- **Reports** — Today's sales, weekly sales, top-selling products
- **User Management** — Admin/Cashier CRUD with role management
- **Bluetooth Printer** — ESC/POS receipt printing, 58mm & 80mm support, test print
- **Offline First** — All data stored in SQLite, no internet required
- **Responsive** — Works on phones and tablets

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (stable) |
| Language | Dart (null safety) |
| State Management | Provider |
| Database | SQLite (sqflite) |
| Bluetooth Printing | flutter_bluetooth_serial + esc_pos_utils + esc_pos_bluetooth |

---

## Project Structure

```
lib/
├── core/
│   ├── database/        # DatabaseHelper (SQLite)
│   ├── models/          # Data models
│   └── services/        # Business logic / DAO
├── features/
│   ├── auth/            # Login screen
│   ├── dashboard/       # Dashboard
│   ├── products/        # Products CRUD
│   ├── customers/       # Customers CRUD
│   ├── sales/           # Billing/POS screen
│   ├── estimations/     # Quotation module
│   ├── reports/         # Reports
│   ├── users/           # User management
│   ├── store/           # Store setup
│   └── printer/         # Bluetooth printer settings
└── main.dart
```

---

## Android Permissions

| Permission | Purpose |
|---|---|
| BLUETOOTH_SCAN, BLUETOOTH_CONNECT | Android 12+ Bluetooth |
| BLUETOOTH, BLUETOOTH_ADMIN | Android < 12 Bluetooth |
| ACCESS_FINE_LOCATION | Required for BT scan on older Android |
| CAMERA | Product image capture |
| READ/WRITE_EXTERNAL_STORAGE | Image access |

---

## Build Requirements

- Flutter SDK (stable channel)
- Java 17
- Android SDK (compileSdk 34, minSdk 21, targetSdk 34)

---

## Build Commands

```bash
# Install dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Install on device
flutter install
```

---

## CI/CD — Codemagic

The project includes a `codemagic.yaml` workflow that:

1. Sets up Flutter stable + Java 17
2. Runs `flutter pub get`
3. Builds the release APK
4. Exports the APK as an artifact

Upload this project to GitHub and connect to [codemagic.io](https://codemagic.io) to trigger CI builds.

---

## Default Credentials

| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |

---

## Database Tables

- `stores` — Store configuration
- `users` — User accounts with roles
- `products` — Product catalog
- `customers` — Customer records
- `sales` — Sales transactions
- `sale_items` — Line items for each sale
- `estimations` — Quotations
- `estimation_items` — Line items for quotations

---

## Bluetooth Printer

1. Go to **Printer Settings** from the dashboard
2. Tap **Scan Devices** to find nearby Bluetooth printers
3. Select your printer and choose paper size (58mm / 80mm)
4. Tap **Test Print** to verify
5. Receipts print automatically after each sale (if printer is selected)
