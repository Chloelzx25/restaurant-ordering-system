const Order = require('../models/Order');

class OrderController {
    static async placeOrder(req, res) {
        try {
            const memberId = req.session.userId;
            const result   = await Order.placeOrders(memberId);
            res.json({ success: true, processed: result.processed, skipped: result.skipped, message: result.message });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
}
module.exports = OrderController;