const Cart = require('../models/Cart');

class CartController {
    static async createCartItem(req, res) {
        try {
            const memberId = req.session.userId;
            const { product_id, quantity } = req.body;
            const item = await Cart.createCartItem(memberId, product_id, quantity);
            res.json({ success: true, message: 'Item added to cart.', item });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
 // GET /cart/retrieve/all
    static async getCartItems(req, res) {
        try {
            const memberId = req.session.userId;
            const items = await Cart.getCartItems(memberId);
            res.json({ success: true, items });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
 }
 // GET /cart/summary
    static async getCartSummary(req, res) {
        try {
            const memberId = req.session.userId;
            const summary = await Cart.getCartSummary(memberId);
            res.json({ success: true, summary });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
 // PUT /cart/:cartItemId
    static async updateCartItem(req, res) {
        try {
            const memberId = req.session.userId;
            const cartItemId = parseInt(req.params.cartItemId);
            const { quantity } = req.body;
            if (!quantity) {
                return res.json({ success: false, message: 'Quantity is required.' });
            }
            const item = await Cart.updateCartItem(memberId, cartItemId, quantity);
            res.json({ success: true, message: 'Cart item updated.', item });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
 // DELETE /cart/:cartItemId
    static async deleteCartItem(req, res) {
        try {
            const memberId = req.session.userId;
            const cartItemId = parseInt(req.params.cartItemId);
            await Cart.deleteCartItem(memberId, cartItemId);
            res.json({ success: true, message: 'Cart item deleted.' });
        } catch (error) {
            res.json({ success: false, message: error.message });
        }
    }
}
module.exports = CartController;
