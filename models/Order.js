const pool = require('../config/database');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class Order {
    static async placeOrders(memberId) {
        const cart = await prisma.cart.findUnique({
            where: { memberId }
        });
        if (!cart) {
            throw new Error('No cart found. Please add items to your cart first.');
        }
        const result = await pool.query(
            'CALL place_orders($1, $2, NULL, NULL, NULL)',
            [memberId, cart.cartId]
        );
        const row = result.rows[0];
        return {
            processed: row.p_processed,
            skipped:   row.p_skipped,
            message:   row.p_message
        };
    }
}
module.exports = Order;