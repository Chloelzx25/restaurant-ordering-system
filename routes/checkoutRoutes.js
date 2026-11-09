const express            = require('express');
const router             = express.Router();
const CheckoutController = require('../controllers/checkoutController');
const { ensureAuthenticated } = require('../middleware/auth');
const path               = require('path');

router.use(ensureAuthenticated);

// Serve checkout page
router.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../views/checkout.html'));
});

router.get('/summary', CheckoutController.getCheckoutSummary);

module.exports = router;