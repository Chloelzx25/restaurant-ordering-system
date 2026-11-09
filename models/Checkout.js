const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class Checkout {

    static async getCheckoutSummary(memberId) {

        const cart = await prisma.cart.findUnique({
            where:   { memberId },
            include: {
                cartItems: {
                    include: { product: true },
                    orderBy: { cartItemId: 'asc' }
                }
            }
        });

        if (!cart || cart.cartItems.length === 0) {
            throw new Error('Your cart is empty.');
        }

        const items = cart.cartItems;

        // Calculate raw subtotal and max quantity of any single item
        let subtotal    = 0;
        let maxQuantity = 0;

        items.forEach(item => {
            subtotal    += parseFloat(item.unitPrice) * item.quantity;
            maxQuantity  = Math.max(maxQuantity, item.quantity);
        });

        // Fetch all active discounts from database
        const discounts = await prisma.discount.findMany({
            where: { isActive: true }
        });

        let discountAmount     = 0;
        const appliedDiscounts = [];

        // QUANTITY discounts: applies if any item quantity >= minQuantity
        const quantityDiscounts = discounts
            .filter(d => d.type === 'QUANTITY' && maxQuantity >= d.minQuantity)
            .sort((a, b) => parseFloat(b.percentage) - parseFloat(a.percentage));

        for (const d of quantityDiscounts) {
            const saving = subtotal * (parseFloat(d.percentage) / 100);
            discountAmount += saving;
            appliedDiscounts.push({
                description: d.description,
                percentage:  parseFloat(d.percentage),
                saving:      parseFloat(saving.toFixed(2))
            });
        }

        // CART_VALUE discounts: applies if subtotal >= minCartValue
        const cartValueDiscounts = discounts
            .filter(d => d.type === 'CART_VALUE' && subtotal >= parseFloat(d.minCartValue))
            .sort((a, b) => parseFloat(b.percentage) - parseFloat(a.percentage));

        for (const d of cartValueDiscounts) {
            const saving = subtotal * (parseFloat(d.percentage) / 100);
            discountAmount += saving;
            appliedDiscounts.push({
                description: d.description,
                percentage:  parseFloat(d.percentage),
                saving:      parseFloat(saving.toFixed(2))
            });
        }

        const discountedSubtotal = Math.max(0, subtotal - discountAmount);

        // Delivery tier — find highest matching threshold
        const tiers = await prisma.deliveryTier.findMany({
            where:   { minOrderValue: { lte: discountedSubtotal } },
            orderBy: { minOrderValue: 'desc' }
        });

        const deliveryTier = tiers[0] || { deliveryFee: 8, description: 'Standard delivery' };
        const deliveryFee  = parseFloat(deliveryTier.deliveryFee);
        const finalTotal   = parseFloat((discountedSubtotal + deliveryFee).toFixed(2));

        return {
            items: items.map(item => ({
                cartItemId:  item.cartItemId,
                productName: item.product.name,
                description: item.product.description,
                quantity:    item.quantity,
                unitPrice:   parseFloat(item.unitPrice),
                subtotal:    parseFloat((parseFloat(item.unitPrice) * item.quantity).toFixed(2))
            })),
            subtotal:            parseFloat(subtotal.toFixed(2)),
            appliedDiscounts,
            totalDiscountAmount: parseFloat(discountAmount.toFixed(2)),
            discountedSubtotal:  parseFloat(discountedSubtotal.toFixed(2)),
            deliveryFee,
            deliveryDescription: deliveryTier.description,
            finalTotal
        };
    }
}

module.exports = Checkout;