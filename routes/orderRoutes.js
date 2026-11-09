const express         = require('express');
const router          = express.Router();
const OrderController = require('../controllers/orderController');
const { ensureAuthenticated } = require('../middleware/auth');

router.use(ensureAuthenticated);
router.post('/place', OrderController.placeOrder);

module.exports = router;