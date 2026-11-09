// controllers/feedbackController.js
const Feedback         = require('../models/Feedback');
const FeedbackResponse = require('../models/FeedbackResponse');
const SaleOrder        = require('../models/SaleOrder');

class FeedbackController {

    // POST /feedback
    static async createFeedback(req, res) {
        try {
            const memberId  = req.session.userId;
            const { product_id, rating, comment } = req.body;

            if (!product_id || !rating || !comment) {
                return res.json({ success: false, message: 'All fields are required.' });
            }

            // Auto-fetch the completed order ID for this member + product
            const saleOrderId = await SaleOrder.getCompletedOrderId(memberId, product_id);
            if (!saleOrderId) {
                return res.json({ success: false, message: 'You have no completed order for this product.' });
            }

            const result = await Feedback.create(memberId, product_id, saleOrderId, rating, comment);

            if (result.startsWith('ERROR')) {
                return res.json({ success: false, message: result.replace('ERROR: ', '') });
            }
            res.json({ success: true, message: 'Feedback submitted successfully.' });

        } catch (error) {
            console.error('Error creating feedback:', error);
            res.status(500).json({ success: false, message: 'An error occurred while submitting feedback.' });
        }
    }

    // PUT /feedback/:id
    static async updateFeedback(req, res) {
        try {
            const memberId   = req.session.userId;
            const feedbackId = parseInt(req.params.id);
            const { rating, comment } = req.body;

            if (!rating || !comment) {
                return res.json({ success: false, message: 'Rating and comment are required.' });
            }

            const result = await Feedback.update(feedbackId, memberId, rating, comment);

            if (result.startsWith('ERROR')) {
                return res.json({ success: false, message: result.replace('ERROR: ', '') });
            }
            res.json({ success: true, message: 'Feedback updated successfully.' });

        } catch (error) {
            console.error('Error updating feedback:', error);
            res.status(500).json({ success: false, message: 'An error occurred while updating feedback.' });
        }
    }

    // DELETE /feedback/:id
    static async deleteFeedback(req, res) {
        try {
            const memberId   = req.session.userId;
            const feedbackId = parseInt(req.params.id);

            const result = await Feedback.delete(feedbackId, memberId);

            if (result.startsWith('ERROR')) {
                return res.json({ success: false, message: result.replace('ERROR: ', '') });
            }
            res.json({ success: true, message: 'Feedback deleted successfully.' });

        } catch (error) {
            console.error('Error deleting feedback:', error);
            res.status(500).json({ success: false, message: 'An error occurred while deleting feedback.' });
        }
    }

    // GET /feedback/my
    static async getMyFeedback(req, res) {
        try {
            const memberId     = req.session.userId;
            const feedbackList = await Feedback.getByMember(memberId);
            res.json({ success: true, feedback: feedbackList });
        } catch (error) {
            console.error('Error retrieving feedback:', error);
            res.status(500).json({ success: false, message: 'An error occurred while retrieving feedback.' });
        }
    }

    // GET /feedback/product/:productId
    static async getFeedbackByProduct(req, res) {
        try {
            const productId    = parseInt(req.params.productId);
            const feedbackList = await Feedback.getByProduct(productId);
            res.json({ success: true, feedback: feedbackList });
        } catch (error) {
            console.error('Error retrieving product feedback:', error);
            res.status(500).json({ success: false, message: 'An error occurred while retrieving feedback.' });
        }
    }

    // POST /feedback/:feedbackId/response
    static async createResponse(req, res) {
        try {
            const memberId   = req.session.userId;
            const feedbackId = parseInt(req.params.feedbackId);
            const { comment } = req.body;

            if (!comment) {
                return res.json({ success: false, message: 'Comment is required.' });
            }

            const result = await FeedbackResponse.create(feedbackId, memberId, comment);

            if (result.startsWith('ERROR')) {
                return res.json({ success: false, message: result.replace('ERROR: ', '') });
            }
            res.json({ success: true, message: 'Response submitted successfully.' });

        } catch (error) {
            console.error('Error creating response:', error);
            res.status(500).json({ success: false, message: 'An error occurred while submitting response.' });
        }
    }

    // GET /feedback/:feedbackId/response
    static async getResponses(req, res) {
        try {
            const feedbackId = parseInt(req.params.feedbackId);
            const responses  = await FeedbackResponse.getByFeedback(feedbackId);
            res.json({ success: true, responses });
        } catch (error) {
            console.error('Error retrieving responses:', error);
            res.status(500).json({ success: false, message: 'An error occurred while retrieving responses.' });
        }
    }

    // DELETE /feedback/response/:responseId
    static async deleteResponse(req, res) {
        try {
            const memberId   = req.session.userId;
            const responseId = parseInt(req.params.responseId);

            const result = await FeedbackResponse.delete(responseId, memberId);

            if (result.startsWith('ERROR')) {
                return res.json({ success: false, message: result.replace('ERROR: ', '') });
            }
            res.json({ success: true, message: 'Response deleted successfully.' });

        } catch (error) {
            console.error('Error deleting response:', error);
            res.status(500).json({ success: false, message: 'An error occurred while deleting response.' });
        }
    }
}

module.exports = FeedbackController;