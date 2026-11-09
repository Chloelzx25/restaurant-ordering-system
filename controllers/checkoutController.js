const Checkout = require('../models/Checkout');

class CheckoutController {

    // GET /checkout/summary
    static async getCheckoutSummary(req, res) {
        try {
            const memberId = req.session.userId;
            const summary  = await Checkout.getCheckoutSummary(memberId);
            res.json({ success: true, summary });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
}

module.exports = CheckoutController;