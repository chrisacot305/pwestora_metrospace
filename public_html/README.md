# Pwestora — Web Admin (Lessor + SuperAdmin, merged)

## What's in this phase
- One login for both roles (`login.php`). The `role` column in `users`
  decides which sidebar/menu the person sees after logging in.
- Lessor self-registration with a "pending verification" state (`register.php`, `pending.php`).
- Full database schema for every module in both prototypes (`schema.sql`).
- Working, real (not fake-data) **Dashboard** overview for both roles.
- Every other menu item (Applications, Installments, Verify Lessors, etc.)
  shows a "coming soon" placeholder — these get built module-by-module next.

## Deploy on Hostinger (summary — see chat for the full walkthrough)
1. hPanel → Databases → MySQL Databases → create a database + user, grant ALL privileges.
2. Open phpMyAdmin → select your new database → Import → upload `schema.sql`.
3. Edit `config.php`: set `DB_NAME`, `DB_USER`, `DB_PASS` to what you just created.
4. Upload the whole `pwestora/` folder into `public_html/` (File Manager → Extract if you zipped it).
5. Visit `https://pwestora.com/tools/create_admin.php` once to create your SuperAdmin login.
6. **Delete `tools/create_admin.php`** from the server after that.
7. Visit `https://pwestora.com/login.php` and log in.

## Folder map
```
config.php              DB connection — edit this first
schema.sql               Import into phpMyAdmin
login.php / register.php / pending.php / logout.php
dashboard.php             Router: loads modules/{page}.php by role
includes/
  auth.php                Session + role guard helpers
  header.php / footer.php Shared shell + role-based sidebar
  sidebar_nav.php          Per-role menu definitions
modules/
  overview_lessor.php      Live dashboard for Admin (Lessor)
  overview_superadmin.php  Live dashboard for SuperAdmin
assets/css/style.css       Brand colors matching the original prototypes
tools/create_admin.php     One-time SuperAdmin creator — delete after use
```
