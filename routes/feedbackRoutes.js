const express            = require('express');
const router             = express.Router();
const FeedbackController = require('../controllers/feedbackController');
const { ensureAuthenticated } = require('../middleware/auth');

router.use(ensureAuthenticated);

router.get('/my',                     FeedbackController.getMyFeedback);
router.get('/product/:productId',     FeedbackController.getFeedbackByProduct);
router.post('/',                      FeedbackController.createFeedback);
router.put('/:id',                    FeedbackController.updateFeedback);
router.delete('/:id',                 FeedbackController.deleteFeedback);

router.delete('/response/:responseId', FeedbackController.deleteResponse);
router.get('/:feedbackId/response',   FeedbackController.getResponses);
router.post('/:feedbackId/response',  FeedbackController.createResponse);

module.exports = router;