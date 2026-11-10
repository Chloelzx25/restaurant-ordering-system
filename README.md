# Restaurant Ordering System

A full-stack restaurant ordering web app built with **Node.js, PostgreSQL, Prisma and Bootstrap**, following MVC architecture. Built across two modules at Singapore Polytechnic (CA1 and CA2).

![Checkout page with order items, stacked discounts and free delivery](images/checkout.png)

## Features
- **Authentication**: session-based login and registration with role-based access (ADMIN / USER)
- **Feedback management**: members can create, view, update and delete feedback for products they have ordered (COMPLETED orders only)
- **Responses**: members can reply to other members' feedback and delete their own replies
- **Admin dashboard**: order summary with filtering by date range and product category, and sorting by order date, amount, customer name or status
- **Cart management** *(Prisma ORM)*: add, update, remove and view cart items. Adding an existing product increases its quantity instead of creating a duplicate row
- **Checkout with discounts and delivery tiers**: stackable discounts (e.g. 10% off for 3 or more of any item, 5% off for orders of $100 or more) and tiered delivery fees, all calculated on the server from the `discount` and `delivery_tier` tables
- **Order placement with transaction handling**: the `place_orders` stored procedure processes each cart item on its own. Available items become an order and leave the cart. Unavailable items stay in the cart without rolling back the others
- **Query performance**: six queries on a separate `manufacturer` table, each paired with a purpose-built index (single-column, composite and covering) and EXPLAIN ANALYSE evidence of the speed-up

## Design highlights
- Each member has **one cart**, and a unique key stops duplicate products
- The **price is saved when an item is added**, so later menu changes don't alter existing orders
- **Discount and delivery rules live in their own tables**, so new rules need only an INSERT, not a code change

## Tech stack
Node.js · PostgreSQL · Prisma · Bootstrap · HTML / CSS / JavaScript

## Getting started

### Prerequisites
- Node.js v18 or above
- PostgreSQL
- pgAdmin (optional)

### 1. Clone and install
```bash
git clone https://github.com/Chloelzx25/restaurant-ordering-system.git
cd restaurant-ordering-system
npm install
```

### 2. Set up the database
1. In pgAdmin, create a database named `restaurant_db`
2. Restore the backup in the `database/` folder to seed the initial data
3. In the query tool, run `functions_and_stored_procedures.sql` to create the stored procedures and functions
4. Create the cart and pricing tables (`cart`, `cart_item`, `discount`, `delivery_tier`):
   ```bash
   npx prisma migrate deploy
   ```
5. Seed the `discount` and `delivery_tier` rules
6. Run `CA2_sql.sql` to create the `place_orders` stored procedure

### 3. Configure environment variables
Create a `.env` file in the root folder (it is not included in this repo):
```
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your-password
DB_NAME=restaurant_db
DB_PORT=5432
SESSION_SECRET=your-secret-key-here
DATABASE_URL="postgresql://postgres:your-password@localhost:5432/restaurant_db?schema=public"
```

### 4. Start the server
```bash
npm run dev
```
The app runs at `http://localhost:3000`.

## Test accounts

| Role  | Email             | Password    |
|-------|-------------------|-------------|
| Admin | sally@example.com | Password123 |
| User  | teddy@example.com | Password123 |

## How to try it
- **Admin dashboard:** log in as Admin and go to `/dashboard`. Normal users are blocked by middleware.
- **Feedback:** log in as a User, open Products, then View Details on a product. You can only leave feedback on products from your own COMPLETED orders.
- **Responses:** log in as a different User to reply to someone else's feedback. You can't reply to your own.
- **Cart:** as a User, go to `/member/products` and click "Add to Cart". View, update or delete items at `/cart/retrieve/all`.
- **Checkout:** from the cart, click "Checkout" to see discounts and the delivery fee at `/checkout`.
- **Order placement:** click "Place Order". To test an unavailable item, set a product's `is_available` to `false` in pgAdmin first. That item stays in the cart while the rest are ordered.

## Project structure
```
├── config/         database connection
├── controllers/    auth, dashboard, feedback, cart, checkout, order
├── database/       restore file, stored procedures, CA2 SQL
├── middleware/     auth and role checks
├── models/         Feedback, Member, Product, SaleOrder, Cart, Checkout, Order
├── prisma/         schema.prisma and migrations
├── public/         CSS and client-side JavaScript
├── routes/         API and page routes
├── views/          HTML pages
└── server.js
```

## What I learned
- Structuring a Node.js app with MVC
- Modelling relationships (member, cart, product, order) with Prisma
- Handling transactions in stored procedures
- Using indexes and EXPLAIN ANALYSE to speed up queries
