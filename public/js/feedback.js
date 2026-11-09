function stars(r) {
  let s = '';
  for (let i = 1; i <= 5; i++) s += `<span class="${i <= r ? 'text-warning' : 'text-muted'}">★</span>`;
  return s;
}

function showAlert(el, type, msg) {
  el.className = 'alert alert-' + type + ' py-2';
  el.textContent = msg;
  el.style.display = 'block';
}

// ====== UPDATE MODAL ======
function openUpdate(id, rating, comment) {
  document.getElementById('update-id').value = id;
  document.getElementById('update-rating').value = rating;
  document.getElementById('update-comment').value = comment;
  document.getElementById('update-alert').style.display = 'none';
  new bootstrap.Modal(document.getElementById('updateModal')).show();
}

async function submitUpdate() {
  const id = document.getElementById('update-id').value;
  const rating = document.getElementById('update-rating').value;
  const comment = document.getElementById('update-comment').value.trim();
  const alertEl = document.getElementById('update-alert');
  if (!comment) { showAlert(alertEl, 'danger', 'Comment required.'); return; }

  const data = await fetch('/feedback/' + id, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ rating, comment })
  }).then(r => r.json());

  if (data.success) {
    bootstrap.Modal.getInstance(document.getElementById('updateModal')).hide();
    if (typeof window.onFeedbackChanged === 'function') await window.onFeedbackChanged();
  } else {
    showAlert(alertEl, 'danger', data.message);
  }
}

// ====== DELETE FEEDBACK ======
async function delFeedback(id) {
  if (!confirm('Delete this feedback?')) return;
  try {
    const data = await fetch('/feedback/' + id, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' }
    }).then(r => r.json());

    if (data.success) {
      if (typeof window.onFeedbackChanged === 'function') await window.onFeedbackChanged();
    } else {
      alert(data.message);
    }
  } catch (error) {
    console.error('Delete error:', error);
    alert('An error occurred while deleting.');
  }
}

window.onFeedbackChanged = loadMyFeedback;

document.addEventListener('DOMContentLoaded', loadMyFeedback);

async function loadMyFeedback() {
  const data = await fetch('/feedback/my').then(r => r.json());
  const list = document.getElementById('feedback-list');

  if (!list) return; // only runs on my-feedback page

  if (!data.success || data.feedback.length === 0) {
    list.innerHTML = '<p class="text-muted">No feedback submitted yet.</p>';
    return;
  }

  list.innerHTML = data.feedback.map(f => `
    <div id="feedback-${f.feedback_id}" class="mb-3 p-3 border">
      <p class="mb-0"><strong><u>Feedback ID: ${f.feedback_id}</u></strong></p>
      <p class="mb-0"><strong>Product Name:</strong> ${f.product_name}</p>
      <p class="mb-0"><strong>Rating:</strong> ${stars(f.rating)}</p>
      <p class="mb-0"><strong>Comments:</strong> ${f.comment}</p>
      <p class="mb-2"><small class="text-muted">Last Updated: ${new Date(f.updated_at).toLocaleString()}</small></p>
      <button class="btn btn-sm btn-outline-primary me-1" onclick="openUpdate(${f.feedback_id},${f.rating},${JSON.stringify(f.comment)})">Update</button>
      <button class="btn btn-sm btn-outline-danger" onclick="delFeedback(${f.feedback_id})">Delete</button>
    </div>
  `).join('');
}