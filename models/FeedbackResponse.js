// models/FeedbackResponse.js
const pool = require('../config/database');

class FeedbackResponse {

    static async create(feedbackId, memberId, comment) {
        const result = await pool.query(
            `SELECT create_response($1::INTEGER, $2::INTEGER, $3::TEXT) AS result`,
            [feedbackId, memberId, comment]
        );
        return result.rows[0].result;
    }

    static async getByFeedback(feedbackId) {
        const result = await pool.query(
            `SELECT * FROM get_response($1::INTEGER)`,
            [feedbackId]
        );
        return result.rows;
    }

    static async delete(responseId, memberId) {
        const result = await pool.query(
            `SELECT delete_response($1::INTEGER, $2::INTEGER) AS result`,
            [responseId, memberId]
        );
        return result.rows[0].result;
    }
}

module.exports = FeedbackResponse;