async function addToCart() {
    const productId = document.getElementById('product-id').value.trim();
    const quantity = document.getElementById('quantity').value.trim();
    const alertEl = document.getElementById('alert-box');

    if (!productId || !quantity) {
        showAlert(alertEl, 'danger', 'Product ID and quantity are required.');
        return;
    }
    if (parseInt(productId) < 1) {
        showAlert(alertEl, 'danger', 'Please enter a valid product ID.');
        return;
    }
    if (parseInt(quantity) < 1) {
        showAlert(alertEl, 'danger', 'Quantity must be at least 1.');
        return;
    }

    const data = await fetch('/cart/create', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            product_id: productId,
            quantity
        })
    }).then(r => r.json());

    if (data.success) {
        showAlert(alertEl, 'success', 'Item added to cart!');

        document.getElementById('quantity').value = '1';
    } else {
        showAlert(alertEl, 'danger', data.message);
    }
}


// ── PREFILL PRODUCT ID (cart-create.html) ───────────────────

document.addEventListener('DOMContentLoaded', () => {
    const productIdInput = document.getElementById('product-id');
    if (productIdInput) {
        const params = new URLSearchParams(window.location.search);
        const productId = params.get('product_id');
        if (productId) {
            productIdInput.value = productId;
            // move focus straight to quantity since product id is already filled
            const quantityInput = document.getElementById('quantity');
            if (quantityInput) quantityInput.focus();
        }
    }
});


// ── LOAD CART (cart-retrieve.html) ──────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('cart-table-body')) {
        loadCart();
    }
});

async function loadCart() {
    const [itemsRes, summaryRes] = await Promise.all([
        fetch('/cart/items').then(r => r.json()),
        fetch('/cart/summary').then(r => r.json())
    ]);

    const tbody = document.getElementById('cart-table-body');
    const noItems = document.getElementById('no-items');
    const summary = document.getElementById('cart-summary');

    if (!itemsRes.success || itemsRes.items.length === 0) {
        tbody.innerHTML = '';
        noItems.style.display = 'block';
        summary.style.display = 'none';
        return;
    }

    noItems.style.display = 'none';
    summary.style.display = 'block';

    tbody.innerHTML = itemsRes.items.map(item => {
    const subtotal = (parseFloat(item.unitPrice) * item.quantity).toFixed(2);
    return `
        <tr id="row-${item.cartItemId}">
            <td>${item.product.name}</td>
            <td>${item.product.description || '-'}</td>
            <td>${subtotal}</td>
            <td>${parseFloat(item.unitPrice).toFixed(2)}</td>
            <td>
                <input type="number" id="qty-${item.cartItemId}"
                       value="${item.quantity}" min="1"
                       class="form-control form-control-sm" style="width:80px;">
            </td>
            <td>
                <button class="btn btn-sm btn-outline-primary"
                        onclick="updateItem(${item.cartItemId})">Update</button>
            </td>
            <td>
                <button class="btn btn-sm btn-outline-danger"
                        onclick="deleteItem(${item.cartItemId})">Delete</button>
            </td>
        </tr>`;
}).join('');

    // Update summary
    if (summaryRes.success) {
        document.getElementById('summary-quantity').textContent =
            summaryRes.summary.totalQuantity;

        document.getElementById('summary-price').textContent =
            summaryRes.summary.totalCheckoutPrice.toFixed(2);
    }
}


// ── UPDATE ITEM ──────────────────────────────────────────────

async function updateItem(cartItemId) {
    const quantity =
        document.getElementById('qty-' + cartItemId).value;

    const alertEl = document.getElementById('alert-box');

    const data = await fetch('/cart/' + cartItemId, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            quantity
        })
    }).then(r => r.json());

    if (data.success) {
        await loadCart(); // reload so summary updates too
    } else {
        showAlert(alertEl, 'danger', data.message);
    }
}


// ── DELETE ITEM ──────────────────────────────────────────────

async function deleteItem(cartItemId) {
    if (!confirm('Remove this item from cart?')) {
        return;
    }

    const alertEl = document.getElementById('alert-box');

    const data = await fetch('/cart/' + cartItemId, {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json'
        }
    }).then(r => r.json());

    if (data.success) {
        await loadCart(); // reload so summary updates too
    } else {
        showAlert(alertEl, 'danger', data.message);
    }
}


// ── SHARED HELPER ────────────────────────────────────────────

function showAlert(el, type, msg) {
    el.className = 'alert alert-' + type + ' py-2';
    el.textContent = msg;
    el.style.display = 'block';
}