// js/common.js
// Shared logic used across every page: login protection, sidebar, logout.

function requireLogin() {
  const currentUser = JSON.parse(localStorage.getItem('currentUser'));
  if (!currentUser) {
    window.location.href = 'login.html';
  }
  return currentUser;
}

function renderSidebar(activePage) {
  const links = [
    { page: 'dashboard', href: 'dashboard.html', icon: 'bi-speedometer2', label: 'Dashboard' },
    { page: 'users', href: 'users.html', icon: 'bi-people-fill', label: 'Users' },
    { page: 'organizations', href: 'organizations.html', icon: 'bi-building', label: 'Organizations' },
    { page: 'plans', href: 'plans.html', icon: 'bi-box-seam-fill', label: 'Plans' },
    { page: 'subscriptions', href: 'subscriptions.html', icon: 'bi-arrow-repeat', label: 'Subscriptions' },
    { page: 'resources', href: 'resources.html', icon: 'bi-hdd-stack-fill', label: 'Resources' },
    { page: 'resource-health', href: 'resource-health.html', icon: 'bi-heart-pulse-fill', label: 'Resource Health' },
    { page: 'billing', href: 'billing.html', icon: 'bi-receipt', label: 'Billing' },
    { page: 'tickets', href: 'tickets.html', icon: 'bi-ticket-detailed-fill', label: 'Tickets' },
    { page: 'reports', href: 'reports.html', icon: 'bi-graph-up-arrow', label: 'Reports' }
  ];

  const linksHtml = links.map(link => {
    const activeClass = link.page === activePage ? 'active' : '';
    return `<a href="${link.href}" class="sidebar-link ${activeClass}"><i class="bi ${link.icon}"></i>&nbsp;&nbsp;${link.label}</a>`;
  }).join('');

  const currentUser = JSON.parse(localStorage.getItem('currentUser')) || {};
  const pageTitle = links.find(l => l.page === activePage)?.label || '';

  document.getElementById('sidebar').innerHTML = `
    <div class="sidebar-brand"><i class="bi bi-cloud-fill"></i> Cloud Manager</div>
    <div class="sidebar-links">${linksHtml}</div>
    <div class="sidebar-footer">
      <div class="fw-semibold" style="font-size:0.85rem;">${currentUser.full_name ?? ''}</div>
      <div class="text-muted mb-2" style="font-size:0.78rem;">${currentUser.role_name ?? ''}</div>
      <button onclick="logout()" class="btn btn-sm btn-outline-secondary w-100"><i class="bi bi-box-arrow-right"></i> Log Out</button>
    </div>
  `;

  const topbar = document.getElementById('topbar');
  if (topbar) {
    const activeLink = links.find(l => l.page === activePage);
    topbar.innerHTML = `<i class="bi ${activeLink?.icon ?? ''}"></i> ${pageTitle}`;
  }
}

function logout() {
  localStorage.removeItem('currentUser');
  window.location.href = 'login.html';
}

// Filters <tr> rows inside a table body based on text typed into a search box.
function enableTableSearch(inputId, tableBodyId) {
  const input = document.getElementById(inputId);
  if (!input) return;

  input.addEventListener('input', () => {
    const query = input.value.toLowerCase();
    const rows = document.querySelectorAll(`#${tableBodyId} tr`);
    rows.forEach(row => {
      const text = row.textContent.toLowerCase();
      row.style.display = text.includes(query) ? '' : 'none';
    });
  });
}

// Same idea, but for card-based layouts (like the Plans page) instead of table rows.
function enableCardSearch(inputId, containerId, cardSelector) {
  const input = document.getElementById(inputId);
  if (!input) return;

  input.addEventListener('input', () => {
    const query = input.value.toLowerCase();
    const cards = document.querySelectorAll(`#${containerId} ${cardSelector}`);
    cards.forEach(card => {
      const text = card.textContent.toLowerCase();
      card.style.display = text.includes(query) ? '' : 'none';
    });
  });
}