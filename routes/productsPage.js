const express = require('express');
const path    = require('path');
const { ensureAuthenticated } = require('../middleware/auth');
const router  = express.Router();
 
router.get('/products', ensureAuthenticated, (req, res) => {
    res.sendFile(path.join(__dirname, '../views/products.html'));
});
 
router.get('/product-detail', ensureAuthenticated, (req, res) => {
    res.sendFile(path.join(__dirname, '../views/product-detail.html'));
});
 
router.get('/my-feedback', ensureAuthenticated, (req, res) => {
    res.sendFile(path.join(__dirname, '../views/my-feedback.html'));
});
 
module.exports = router;