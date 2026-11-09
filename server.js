const express    = require('express');
const session    = require('express-session');
const bodyParser = require('body-parser');
const path       = require('path');
require('dotenv').config();

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.use(session({
    secret: process.env.SESSION_SECRET || 'your-secret-key',
    resave: false,
    saveUninitialized: false,
}));

app.use(express.static('public'));

app.use('/',          require('./routes/auth'));
app.use('/dashboard', require('./routes/dashboard'));
app.use('/products',  require('./routes/products'));
app.use('/member',    require('./routes/productsPage'));
app.use('/feedback',  require('./routes/feedbackRoutes'));
app.use('/api',       require('./routes/api'));
app.use('/cart',      require('./routes/cartRoutes'));
app.use('/checkout', require('./routes/checkoutRoutes'));
app.use('/order', require('./routes/orderRoutes'));

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});