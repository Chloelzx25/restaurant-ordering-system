How to run

This completes the full Node.js application following MVC principles with all the required features for the restaurant ordering system assignment. The application includes:

Database Design: Complete PostgreSQL schema with stored procedures
MVC Architecture: Proper separation of concerns
Feedback Management: Full CRUD operations for dining feedback
Response Management: Create, read, and delete responses
Admin Dashboard: Order summary with filtering and sorting
Authentication: Session-based auth with role-based access control
Responsive UI: Bootstrap-based interface
To run the application:

Install dependencies: npm install
Set up PostgreSQL database and run the schema and seed scripts
Configure environment variables in .env
Start the server: npm start or npm run dev



extra info:
The Files You Need Are:
✅ public/js/main.js (provided)
✅ views/login.html (provided)
✅ views/register.html (provided)
✅ views/feedback/index.html (* you create *)
✅ views/feedback/create.html (* you create *)
✅ views/feedback/edit.html (* you create *)
✅ views/dashboard.html (provided)
✅ views/product-detail.html (provided)
✅ views/products.html (provided)

# Restaurant Ordering System - CA1

A Node.js web application for a restaurant ordering system built with MVC architecture, PostgreSQL, and Bootstrap.

## Prerequisites

- Node.js (v18 or above)
- PostgreSQL
- pgAdmin (optional, for database management)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <https://github.com/SOCDBS/ca1-assignment-Chloelzx25 >
cd restaurant_ordering_system
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up the Database

1. Open pgAdmin and connect to your PostgreSQL server
2. Create a new database named `restaurant_db`
3. Restore the provided database backup to seed the initial data (refer to the `database/` folder)
4. Open the query tool and run `functions_and_stored_procedures.sql` to create all stored procedures and functions
5. Run `prisma/migrations` to create the CA2 tables (`cart`, `cart_item`, `discount`, `delivery_tier`):
```bash
   npx prisma migrate deploy
6. Seed the `discount` and `delivery_tier` rules
7. Create the `place_orders` stored procedure (order placement transaction handling)
### 4. Configure Environment Variables

Create a `.env` file in the root directory:

```
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=restaurant_db
DB_PORT=5432
SESSION_SECRET=your-secret-key-here

DATABASE_URL="postgresql://postgres:password@localhost:5432/restaurant_db?schema=public"
```

### 5. Start the Server

```bash
npm run dev
```

The application will be running at `http://localhost:3000`

## Test Accounts

| Role  | Email             | Password    |
|-------|-------------------|-------------|
| Admin | sally@example.com | Password123 |
| User  | teddy@example.com | Password123 |

## Project Structure

```
├── config/
│ └── database.js
├── controllers/
│ ├── authController.js
│ ├── dashboardController.js
│ ├── feedbackController.js
│ ├── cartController.js
│ ├── checkoutController.js
│ └── orderController.js
├── database/
│ └── restaurant_db_restore.sql
│
├── middleware/
│ └── auth.js
├── models/
│ ├── Feedback.js
│ ├── FeedbackResponse.js
│ ├── Member.js
│ ├── Product.js
│ ├── SaleOrder.js
│ ├── Cart.js
│ ├── Checkout.js
│ └── Order.js
├── prisma/
│ ├── schema.prisma
│ └── migrations/
├── public/
│ ├── css/
│ │ └── style.css
│ └── js/
│ ├── main.js
│ ├── dashboard.js
│ ├── product-detail.js
│ ├── feedback.js
│ ├── cart.js
│ └── checkout.js
├── routes/
│ ├── auth.js
│ ├── api.js
│ ├── dashboard.js
│ ├── feedbackRoutes.js
│ ├── products.js
│ ├── productsPage.js
│ ├── cartRoutes.js
│ ├── checkoutRoutes.js
│ └── orderRoutes.js
├── views/
│ ├── login.html
│ ├── register.html
│ ├── dashboard.html
│ ├── products.html
│ ├── product-detail.html
│ ├── my-feedback.html
│ ├── cart-create.html
│ ├── cart-retrieve.html
│ └── checkout.html
├── .env
├── server.js
├── package.json
│
│
├──functions_&_stored_procedures.sql
└──functions_and_stored_procedures.sql


```

- **Authentication** — Session-based login and registration with role-based access (ADMIN / USER)
- **Feedback Management** — Members can create, view, update and delete feedback for products they have ordered (COMPLETED orders only)
- **Response Management** — Members can reply to other members' feedback and delete their own responses
- **Admin Dashboard** — Admins can view an order summary with filtering by date range and product category, and sorting by order date, amount, customer name or status
- **Cart Management** *(CA2)* — Members can add, update, remove, and view items in their own shopping cart, backed entirely by Prisma ORM. Adding an existing product increments its quantity instead of creating a duplicate row.
- **Checkout with Discounts & Delivery Tiers** *(CA2)* — Checkout summary applies QUANTITY and CART_VALUE discount rules (stackable) and calculates delivery fees based on tiered order-value thresholds, all computed server-side from the `discount` and `delivery_tier` tables.
- **Order Placement (Transaction Handling)** *(CA2)* — The `place_orders` stored procedure processes each cart item individually: available items become a `sale_order`/`sale_order_item` (status `PACKING`) and are removed from the cart; unavailable items are skipped and remain in the cart without rolling back already-processed items.
- **Query Performance / Indexing** *(CA2)* — Six proposed queries against the standalone `manufacturer` table, each paired with a purpose-built index (single-column, composite, and covering indexes) and EXPLAIN ANALYSE evidence of the performance improvement.

## Notes for Reviewers

- **To view the Admin Dashboard (Task 3):** Log in with the ADMIN test account above, then navigate to `/dashboard`. Only ADMIN role can access this page; USER accounts are blocked by middleware.
- **To test Feedback:** Log in with the USER test account, go to Products → View Details on any product, and use the Create Feedback form. Feedback can only be submitted for products in a COMPLETED order belonging to the logged-in member.
- **To test Responses:** Log in as a different USER (not the feedback author) to see the Reply option under each feedback entry. The original feedback author cannot respond to their own feedback.
- **To test Cart Management:** Log in with the USER test account, go to `/member/products`, and click "Add to Cart" on any available product (this pre-fills the Product Id on `/cart/create`). View, update, or delete items at `/cart/retrieve/all`.
- **To test Checkout:** From `/cart/retrieve/all`, click "Checkout" to view the price summary with any applicable discounts and delivery fee at `/checkout`.
- **To test Order Placement / Transactions:** From `/checkout`, click "Place Order". To test the "item unavailable" scenario, set a product's `is_available` flag to `false` in pgAdmin before placing the order — that item will remain in the cart while other available items are processed into a new order.
- **Stored procedures/functions:** CA1 functions (`create_feedback`, `update_feedback`, `delete_feedback`, `get_feedback`, `create_response`, `get_response`, `delete_response`, `get_sale_order_summary`) are in `functions_and_stored_procedures.sql`. The CA2 `place_orders` procedure is in `CA2_sql.sql`, both in the `database/` folder. All can be run directly from pgAdmin's query tool.
- **ERD and design assumptions:** The full updated ERD and all design decisions/assumptions for CA2 (cart, discount, delivery_tier) are documented in the CA2 Individual Report.
- **Existing tables:** The original CA1 tables (`member`, `member_role`, `product`, `sale_order`, `sale_order_item`, `feedback`, `feedback_response`) were not modified. CA2 added 4 new tables via Prisma: `cart`, `cart_item`, `discount`, `delivery_tier`.
- **Indexing task:** The `manufacturer` database/table used for the indexing analysis is separate from `restaurant_db` and is not wired into the application — see `CA2_manufacturer_indexing.sql` and the CA2 report for the full before/after evidence.
