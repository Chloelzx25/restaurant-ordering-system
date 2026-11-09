# restaurant-ordering-system
I designed the database for an ordering system with Prisma. Each member has one cart, and a unique key stops duplicate products, so adding the same item raises its quantity. Prices are saved when an item is added, and discount and delivery-fee rules live in their own tables, so new rules need only an INSERT.
