# My Stock 📦

> A mobile inventory management application built for a real client, replacing manual stock counting and record-keeping with a simple digital system.

---

## 📖 About

My Stock was built to solve a real problem — tracking inventory manually is slow and error-prone. This app lets users check current stock levels, add new items, and record stock-in/out transactions. Every action is automatically logged with the user's name, the item affected, and the timestamp, making it easy to trace any change in the inventory.

---

## ✨ Features

- 📊 **Real-time stock monitoring** — view current quantity of all items at a glance
- ➕ **Stock-in / Stock-out** — record receiving and issuing of items
- 🗒️ **Transaction log** — automatic record of who did what, to which item, and when
- 🔍 **Item management** — add, edit, and manage product entries

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Backend / Database | Supabase |

---

## ⚙️ Installation

1. Clone the repository
   ```bash
   git clone https://github.com/YOUR_USERNAME/my-stock.git
   cd my-stock
   ```
2. Install Flutter dependencies
   ```bash
   flutter pub get
   ```
3. Set up Supabase — create a project at [supabase.com](https://supabase.com), then add your credentials to the app config
   ```dart
   // lib/supabase_config.dart
   const supabaseUrl = 'YOUR_SUPABASE_URL';
   const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. Run the app
   ```bash
   flutter run
   ```

---
