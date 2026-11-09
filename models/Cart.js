const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class Cart {
    static async getOrCreateCart(memberId) {
        return await prisma.cart.upsert({
            where: { memberId },
            update: {},
            create: { memberId }
        });
    }
    
    static async createCartItem(memberId, productId, quantity) {
        if (!productId || !quantity) {
            throw new Error('Product ID and quantity are required.');
        }
        if (quantity < 1) {
            throw new Error('Quantity must be at least 1.');
        }
        
        const product = await prisma.product.findUnique({
            where: { productId: parseInt(productId) }
        });
        if (!product) {
            throw new Error('Product not found.');
        }
        if (!product.isAvailable) {
            throw new Error('This product is currently unavailable.');
        }
        
        const cart = await Cart.getOrCreateCart(memberId);
        
        const existing = await prisma.cartItem.findUnique({
            where: {
                cartId_productId: {
                    cartId: cart.cartId,
                    productId: parseInt(productId)
                }
            }
        });
        if (existing) {
            return await prisma.cartItem.update({
                where: { cartItemId: existing.cartItemId },
                data: { quantity: existing.quantity + parseInt(quantity) }
            });
        }
        
        return await prisma.cartItem.create({
            data: {
                cartId: cart.cartId,
                productId: parseInt(productId),
                quantity: parseInt(quantity),
                unitPrice: product.price
            }
        });
    }
    
    static async getCartItems(memberId) {
        const cart = await prisma.cart.findUnique({
            where: { memberId },
            include: {
                cartItems: {
                    include: { product: true },
                    orderBy: { cartItemId: 'asc' }
                }
            }
        });

        if (!cart) return [];
        return cart.cartItems;
    }
    
    static async getCartSummary(memberId) {
        const items = await Cart.getCartItems(memberId);
        
        const totalQuantity = items.reduce((sum, item) => sum + item.quantity, 0);
        
        const totalPrice = items.reduce((sum, item) => sum + parseFloat(item.unitPrice) * item.quantity, 0);
        
        return {
            totalQuantity,
            totalCheckoutPrice: parseFloat(totalPrice.toFixed(2))
        };
    }
    
    static async updateCartItem(memberId, cartItemId, quantity) {
        if (quantity < 1) {
            throw new Error('Quantity must be at least 1.');
        }
        
        const item = await prisma.cartItem.findUnique({
            where: { cartItemId: parseInt(cartItemId) },
            include: { cart: true }
        });
        
        if (!item) {
            throw new Error('Cart item not found.');
        }
        if (item.cart.memberId !== memberId) {
            throw new Error('You can only update items in your own cart.');
        }
        return await prisma.cartItem.update({
            where: { cartItemId: parseInt(cartItemId) },
            data: { quantity: parseInt(quantity) }
        });
    }
    
    static async deleteCartItem(memberId, cartItemId) {
        const item = await prisma.cartItem.findUnique({
            where: { cartItemId: parseInt(cartItemId) },
            include: { cart: true }
        });
        
        if (!item) {
            throw new Error('Cart item not found.');
        }
        if (item.cart.memberId !== memberId) {
            throw new Error('You can only delete items from your own cart.');
        }
        return await prisma.cartItem.delete({
            where: { cartItemId: parseInt(cartItemId) }
        });
    }
}
module.exports = Cart;