const pool = require('../config/database');

class Feedback {

    static async create(memberId, productId, saleOrderId, rating, comment) {
        const result = await pool.query(
            `SELECT create_feedback($1::INTEGER, $2::INTEGER, $3::INTEGER, $4::SMALLINT, $5::TEXT) AS result`,
            [memberId, productId, saleOrderId, rating, comment]
        );
        return result.rows[0].result;
    }

    static async update(feedbackId, memberId, rating, comment) {
        const result = await pool.query(
            `SELECT update_feedback($1::INTEGER, $2::INTEGER, $3::SMALLINT, $4::TEXT) AS result`,
            [feedbackId, memberId, rating, comment]
        );
        return result.rows[0].result;
    }

    static async delete(feedbackId, memberId) {
        const result = await pool.query(
            `SELECT delete_feedback($1::INTEGER, $2::INTEGER) AS result`,
            [feedbackId, memberId]
        );
        return result.rows[0].result;
    }

    static async getByMember(memberId) {
        const result = await pool.query(
            `SELECT * FROM get_feedback($1::INTEGER)`,
            [memberId]
        );
        return result.rows;
    }

    static async getByProduct(productId) {
        const result = await pool.query(
            `SELECT f.feedback_id, f.member_id, m.username, f.rating, f.comment, f.updated_at
             FROM feedback f
             JOIN member m ON f.member_id = m.member_id
             WHERE f.product_id = $1
             ORDER BY f.updated_at DESC`,
            [productId]
        );
        return result.rows;
    }
}

module.exports = Feedback;