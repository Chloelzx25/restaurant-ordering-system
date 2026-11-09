// routes/api.js
const express = require('express');
const router  = express.Router();
const db      = require('../config/database');
const { ensureAuthenticated, ensureAdmin } = require('../middleware/auth');

// GET /api/auth/status
router.get('/auth/status', (req, res) => {
    if (req.session && req.session.userId) {
        return res.json({
            authenticated: true,
            user: {
                id:   req.session.userId,
                role: req.session.userRole,
                name: req.session.userName
            }
        });
    }
    res.json({ authenticated: false });
});

// GET /api/dashboard  (admin only)
router.get('/dashboard', ensureAuthenticated, ensureAdmin, async (req, res) => {
    try {
        const {
            start_date = null,
            end_date   = null,
            category   = null,
            sort_by    = 'order_date',
            sort_order = 'DESC'
        } = req.query;

        const result = await db.query(
            `SELECT * FROM get_sale_order_summary($1::DATE, $2::DATE, $3::TEXT, $4::TEXT, $5::TEXT)`,
            [
                start_date || null,
                end_date   || null,
                category   || null,
                sort_by,
                sort_order
            ]
        );

        const catResult  = await db.query(
            `SELECT DISTINCT category FROM product WHERE category IS NOT NULL ORDER BY category`
        );
        const categories = catResult.rows.map(r => r.category);

        res.json({
            success:    true,
            orders:     result.rows,
            categories,
            filters: {
                startDate:       start_date,
                endDate:         end_date,
                productCategory: category,
                sortBy:          sort_by,
                sortOrder:       sort_order
            },
            user: {
                name: req.session.userName,
                role: req.session.userRole
            }
        });

    } catch (error) {
        console.error('Dashboard API error:', error);
        res.json({ success: false, message: error.message });
    }
});

module.exports = router;