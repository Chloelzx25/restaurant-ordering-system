const pool = require('../config/database');

class SaleOrder {
    static async getCompletedOrderId(memberId, productId) {

        const result = await pool.query(`
            SELECT so.order_id
            FROM sale_order so
            JOIN sale_order_item soi ON so.order_id = soi.order_id
            WHERE so.member_id = $1
              AND soi.product_id = $2
              AND so.status = 'COMPLETED'
              AND NOT EXISTS (
                  SELECT 1 FROM feedback f
                  WHERE f.member_id = $1
                    AND f.product_id = $2
                    AND f.sale_order_id = so.order_id
              )
            ORDER BY so.order_date ASC
            LIMIT 1
        `, [memberId, productId]);
        return result.rows[0] ? result.rows[0].order_id : null;
    }
}

module.exports = SaleOrder;