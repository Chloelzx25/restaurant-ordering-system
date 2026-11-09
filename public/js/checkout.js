document.addEventListener('DOMContentLoaded', loadCheckout);

async function loadCheckout() {
    const content = document.getElementById('checkout-content');
    const alertEl = document.getElementById('alert-box');

    const response = await fetch('/checkout/summary');
    const res = await response.json();

    if (!res.success) {
        content.innerHTML = '';
        showAlert(alertEl, 'danger', res.message);
        return;
    }

    const s = res.summary;

    // Build items table rows
    const itemRows = s.items.map(item =>
        '<tr>' +
        '<td>' + item.productName + '<br><small class="text-muted">' + (item.description || '') + '</small></td>' +
        '<td>$' + item.unitPrice.toFixed(2) + '</td>' +
        '<td>' + item.quantity + '</td>' +
        '<td>$' + item.subtotal.toFixed(2) + '</td>' +
        '</tr>'
    ).join('');

    // Build discount rows
    let discountRows = '';
    if (s.appliedDiscounts.length > 0) {
        discountRows = s.appliedDiscounts.map(d =>
            '<tr class="text-success">' +
            '<td colspan="3">' + d.description + ' (' + d.percentage + '% off)</td>' +
            '<td>-$' + d.saving.toFixed(2) + '</td>' +
            '</tr>'
        ).join('');
    } else {
        discountRows = '<tr><td colspan="4" class="text-muted">No discounts applied.</td></tr>';
    }

    content.innerHTML =
        // Items card
        '<div class="card mb-3">' +
        '<div class="card-body">' +
        '<h5 class="fw-bold">Order Items</h5>' +
        '<table class="table table-striped">' +
        '<thead><tr><th>Product</th><th>Unit Price</th><th>Quantity</th><th>Subtotal</th></tr></thead>' +
        '<tbody>' + itemRows + '</tbody>' +
        '</table>' +
        '</div></div>' +

        // Price summary card
        '<div class="card mb-3">' +
        '<div class="card-body">' +
        '<h5 class="fw-bold">Price Summary</h5>' +
        '<table class="table">' +
        '<tbody>' +
        '<tr><td>Subtotal</td><td>$' + s.subtotal.toFixed(2) + '</td></tr>' +
        discountRows +
        '<tr><td>After Discounts</td><td>$' + s.discountedSubtotal.toFixed(2) + '</td></tr>' +
        '<tr><td>' + s.deliveryDescription + '</td><td>$' + s.deliveryFee.toFixed(2) + '</td></tr>' +
        '<tr class="fw-bold table-active"><td>Total</td><td>$' + s.finalTotal.toFixed(2) + '</td></tr>' +
        '</tbody></table>' +
        '</div></div>' +

        // Actions
        '<div class="d-flex justify-content-between">' +
        '<a href="/cart/retrieve/all" class="btn btn-outline-secondary">Back to Cart</a>' +
        '<button class="btn btn-primary" onclick="placeOrder()">Place Order</button>' +
        '</div>';
}

async function placeOrder() {
    const alertEl = document.getElementById('alert-box');

    if (!confirm('Place order for all available items in your cart?')) return;

    const res = await fetch('/order/place', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    }).then(r => r.json());

    if (res.success) {
        // Reload checkout to reflect removed items
        showAlert(alertEl, 'success', res.message);

        setTimeout(() => {
            window.location.href = '/cart/retrieve/all';
        }, 2000);
    } else {
        showAlert(alertEl, 'danger', res.message);
    }
}

function showAlert(el, type, msg) {
    el.className     = 'alert alert-' + type + ' py-2';
    el.textContent   = msg;
    el.style.display = 'block';
}