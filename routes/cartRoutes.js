const express = require('express');
const router = express.Router();
const CartController = require('../controllers/cartController');
const { ensureAuthenticated } = require('../middleware/auth');
const path = require('path');

router.use(ensureAuthenticated);

// Serve HTML pages
router.get('/create', (req, res) => {
 res.sendFile(path.join(__dirname, '../views/cart-create.html'));
});

router.get('/retrieve/all', (req, res) => {
 res.sendFile(path.join(__dirname, '../views/cart-retrieve.html'));
});

router.post('/create', CartController.createCartItem);
router.get('/items', CartController.getCartItems);
router.get('/summary', CartController.getCartSummary);
router.put('/:cartItemId', CartController.updateCartItem);
router.delete('/:cartItemId', CartController.deleteCartItem);
module.exports = router;