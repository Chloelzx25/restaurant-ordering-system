document.addEventListener('DOMContentLoaded', loadDashboardData);

async function loadDashboardData() {
    const params = new URLSearchParams();
    const start  = document.getElementById('start_date').value;
    const end    = document.getElementById('end_date').value;
    const cat    = document.getElementById('category').value;
    const sortBy = document.getElementById('sort_by').value;
    const sortOr = document.getElementById('sort_order').value;

    if (start)  params.append('start_date', start);
    if (end)    params.append('end_date', end);
    if (cat)    params.append('category', cat);
    params.append('sort_by', sortBy);
    params.append('sort_order', sortOr);

    try {
        const res  = await fetch('/api/dashboard?' + params.toString());
        const data = await res.json();

        if (!data.success) {
            console.error('API error:', data.message);
            return;
        }

        // Populate category dropdown only on first load
        const catSelect = document.getElementById('category');
        if (catSelect.options.length === 1 && data.categories.length > 0) {
            data.categories.forEach(c => {
                const opt = document.createElement('option');
                opt.value = c;
                opt.textContent = c;
                catSelect.appendChild(opt);
            });
        }

        // Restore selected category after repopulation
        if (cat) catSelect.value = cat;

        // Update welcome message
        if (data.user) {
            document.getElementById('user-welcome').textContent = 'Welcome, ' + data.user.name;
        }

        displayOrders(data.orders);

    } catch (err) {
        console.error('Fetch error:', err);
    }
}

function displayOrders(orders) {
    const tbody    = document.getElementById('orders-tbody');
    const noOrders = document.getElementById('no-orders');
    const table    = document.getElementById('orders-table-container');
    const title    = document.getElementById('order-summary-title');

    title.textContent = 'Order Summary (' + orders.length + ' orders)';

    if (orders.length === 0) {
        table.style.display    = 'none';
        noOrders.style.display = 'block';
        return;
    }

    table.style.display    = 'block';
    noOrders.style.display = 'none';

    tbody.innerHTML = orders.map(o => `
        <tr>
            <td>#${o.order_id}</td>
            <td>${o.customer_name}</td>
            <td>${new Date(o.order_date).toLocaleDateString()}</td>
            <td>$${parseFloat(o.total_amount).toFixed(2)}</td>
            <td><span class="badge bg-${badgeClass(o.status)}">${o.status}</span></td>
            <td>${o.product_count}</td>
            <td>${o.products_ordered}</td>
        </tr>
    `).join('');
}

function badgeClass(status) {
    return { COMPLETED: 'success', CANCELLED: 'danger', PENDING: 'warning', PACKING: 'info' }[status] || 'secondary';
}

function clearFilters() {
    document.getElementById('start_date').value = '';
    document.getElementById('end_date').value   = '';
    document.getElementById('category').value   = '';
    document.getElementById('sort_by').value    = 'order_date';
    document.getElementById('sort_order').value = 'DESC';
    loadDashboardData();
}