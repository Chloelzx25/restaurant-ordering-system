let productId = new URLSearchParams(window.location.search).get('id');
let userId = null;

window.onFeedbackChanged = loadFeedback;

document.addEventListener('DOMContentLoaded', async () => {
    const loading       = document.getElementById('loading');
    const errorMessage  = document.getElementById('error-message');

    if (!productId) {
        loading.style.display = 'none';
        errorMessage.style.display = 'block';
        errorMessage.textContent = 'No product specified.';
        return;
    }

    try {
        const a = await fetch('/api/auth/status').then(r => r.json());
        if (a.authenticated) userId = a.user.id;
    } catch(e) {}

    await loadProduct();
    await loadFeedback();
});

async function loadProduct() {
    const loading      = document.getElementById('loading');
    const errorMessage = document.getElementById('error-message');
    const productDiv   = document.getElementById('product-detail');

    try {
        const data = await fetch('/products/' + productId).then(r => r.json());
        loading.style.display = 'none';

        if (!data.success || !data.product) {
            errorMessage.style.display = 'block';
            return;
        }

        const p = data.product;

        document.title = p.name + ' - Member View';
        document.getElementById('detail-name').textContent        = p.name;
        document.getElementById('detail-category').textContent    = p.category || '-';
        document.getElementById('detail-description').textContent = p.description || '-';
        document.getElementById('detail-price').textContent       = '$' + parseFloat(p.price).toFixed(2);
        document.getElementById('detail-created-at').textContent  = new Date(p.created_at).toLocaleDateString();
        document.getElementById('detail-status').innerHTML = `
            <span class="badge ${p.is_available ? 'bg-success' : 'bg-secondary'}">
                ${p.is_available ? 'Available' : 'Unavailable'}
            </span>`;

        productDiv.style.display = 'block';

        // Show create feedback form
        document.getElementById('create-feedback-section').style.display = 'block';
        document.getElementById('create-feedback-section').innerHTML = `
            <div class="card">
                <div class="card-body">
                    <h5>Create Feedback for ${p.name}</h5>
                    <div id="create-alert" class="alert py-2" style="display:none;"></div>
                    <table>
                        <tr>
                            <td class="pe-3">
                                <label class="form-label">Product Id</label>
                                <input type="text" class="form-control form-control-sm" value="${productId}" readonly style="width:80px;">
                            </td>
                            <td class="pe-3">
                                <label class="form-label">Rating</label>
                                <input type="number" id="fb-rating" class="form-control form-control-sm" min="1" max="5" style="width:80px;">
                            </td>
                            <td class="pe-3">
                                <label class="form-label">Comment Text</label>
                                <textarea id="fb-comment" class="form-control form-control-sm" rows="1" style="width:200px;"></textarea>
                            </td>
                        </tr>
                        <tr>
                            <td colspan="3" class="pt-2">
                                <button class="btn btn-secondary btn-sm" onclick="submitFeedback()">Create</button>
                            </td>
                        </tr>
                    </table>
                </div>
            </div>`;

    } catch (error) {
        console.error('Error fetching product:', error);
        loading.style.display      = 'none';
        errorMessage.style.display = 'block';
    }
}

async function loadFeedback() {
    const data    = await fetch('/feedback/product/' + productId).then(r => r.json());
    const section = document.getElementById('feedback-section');
    section.style.display = 'block';

    let html = '<div class="card"><div class="card-body"><h5 class="text-center fw-bold">Feedback For This Product</h5>';

    if (!data.success || data.feedback.length === 0) {
        html += '<p class="text-muted">No feedback yet.</p></div></div>';
        section.innerHTML = html;
        return;
    }

    for (const f of data.feedback) {
        const isOwner        = userId && f.member_id == userId;
        const escapedComment = f.comment.replace(/'/g, "\\'").replace(/"/g, '&quot;');

        html += `
            <div id="feedback-${f.feedback_id}" class="mb-3">
                <p class="mb-0"><strong>Member Username:</strong> ${f.username}</p>
                <p class="mb-0"><strong>Rating:</strong> ${stars(f.rating)}</p>
                <p class="mb-0"><strong>Comment:</strong> ${f.comment}</p>
                <p class="mb-1"><small class="text-muted">Last Updated: ${new Date(f.updated_at).toLocaleString()}</small></p>
                ${isOwner ? `
                    <button class="btn btn-sm btn-outline-primary me-1" onclick="openUpdate(${f.feedback_id},${f.rating},'${escapedComment}')">Update</button>
                    <button class="btn btn-sm btn-outline-danger" onclick="delFeedback(${f.feedback_id})">Delete</button>
                ` : ''}
                <div id="resp-box-${f.feedback_id}" class="mt-2 p-2 border" style="min-height:50px;"></div>
                ${!isOwner ? `
                    <div class="input-group input-group-sm mt-1" style="max-width:400px;">
                        <input type="text" class="form-control" id="resp-input-${f.feedback_id}" placeholder="Write a response...">
                        <button class="btn btn-outline-secondary" onclick="submitResp(${f.feedback_id})">Reply</button>
                    </div>
                    <div id="resp-alert-${f.feedback_id}" class="alert py-1 mt-1" style="display:none;max-width:400px;"></div>
                ` : ''}
                <hr>
            </div>`;
    }
    html += '</div></div>';
    section.innerHTML = html;
    for (const f of data.feedback) await loadResponses(f.feedback_id);
}

async function loadResponses(feedbackId) {
    const data = await fetch('/feedback/' + feedbackId + '/response').then(r => r.json());
    const box  = document.getElementById('resp-box-' + feedbackId);
    if (!data.success || data.responses.length === 0) {
        box.innerHTML = '<small class="text-muted">No responses yet.</small>';
        return;
    }
    box.innerHTML = data.responses.map(r => {
        const isOwner = userId && r.member_id == userId;
        return `<div class="d-flex justify-content-between mb-1">
            <div><strong>${r.username}</strong> <small class="text-muted">${new Date(r.created_at).toLocaleString()}</small><br>${r.comment}</div>
            ${isOwner ? `<button class="btn btn-sm btn-outline-danger ms-2" onclick="delResp(${r.response_id},${feedbackId})">Delete</button>` : ''}
        </div>`;
    }).join('');
}

async function submitFeedback() {
    const rating  = document.getElementById('fb-rating').value.trim();
    const comment = document.getElementById('fb-comment').value.trim();
    const alertEl = document.getElementById('create-alert');
    if (!rating || !comment) { showAlert(alertEl, 'danger', 'Rating and comment are required.'); return; }
    const data = await fetch('/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_id: productId, rating, comment })
    }).then(r => r.json());
    if (data.success) {
        showAlert(alertEl, 'success', 'Feedback submitted!');
        document.getElementById('fb-rating').value  = '';
        document.getElementById('fb-comment').value = '';
        await loadFeedback();
    } else {
        showAlert(alertEl, 'danger', data.message);
    }
}

async function submitResp(feedbackId) {
    const comment = document.getElementById('resp-input-' + feedbackId).value.trim();
    const alertEl = document.getElementById('resp-alert-' + feedbackId);
    if (!comment) { showAlert(alertEl, 'danger', 'Comment required.'); return; }
    const data = await fetch('/feedback/' + feedbackId + '/response', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ comment })
    }).then(r => r.json());
    if (data.success) {
        document.getElementById('resp-input-' + feedbackId).value = '';
        showAlert(alertEl, 'success', 'Response posted!');
        await loadResponses(feedbackId);
    } else {
        showAlert(alertEl, 'danger', data.message);
    }
}

async function delResp(responseId, feedbackId) {
    if (!confirm('Delete this response?')) return;
    const data = await fetch('/feedback/response/' + responseId, { method: 'DELETE' }).then(r => r.json());
    if (data.success) {
        await loadResponses(feedbackId);
    } else {
        alert(data.message);
    }
}