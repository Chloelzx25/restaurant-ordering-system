-- CreateTable
CREATE TABLE "cart" (
    "cart_id" SERIAL NOT NULL,
    "member_id" INTEGER NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL,

    CONSTRAINT "cart_pkey" PRIMARY KEY ("cart_id")
);

-- CreateTable
CREATE TABLE "cart_item" (
    "cart_item_id" SERIAL NOT NULL,
    "cart_id" INTEGER NOT NULL,
    "product_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "cart_item_pkey" PRIMARY KEY ("cart_item_id")
);

-- CreateTable
CREATE TABLE "discount" (
    "discount_id" SERIAL NOT NULL,
    "type" VARCHAR(20) NOT NULL,
    "min_quantity" INTEGER,
    "min_cart_value" DECIMAL(10,2),
    "percentage" DECIMAL(5,2) NOT NULL,
    "description" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "discount_pkey" PRIMARY KEY ("discount_id")
);

-- CreateTable
CREATE TABLE "delivery_tier" (
    "tier_id" SERIAL NOT NULL,
    "min_order_value" DECIMAL(10,2) NOT NULL,
    "delivery_fee" DECIMAL(10,2) NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "delivery_tier_pkey" PRIMARY KEY ("tier_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cart_member_id_key" ON "cart"("member_id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_item_cart_id_product_id_key" ON "cart_item"("cart_id", "product_id");

-- AddForeignKey
ALTER TABLE "cart" ADD CONSTRAINT "cart_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "member"("member_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "cart_item" ADD CONSTRAINT "cart_item_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "cart"("cart_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "cart_item" ADD CONSTRAINT "cart_item_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "product"("product_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
