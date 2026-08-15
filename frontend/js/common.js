// js/common.js
// Shared logic used across every page: animated background, login protection,
// sidebar, loading bar, logout, and table/card search.

// ---------- Inject the animated grid + glowing orbs into every page ----------
(function injectAnimatedBackground() {
  window.addEventListener('DOMContentLoaded', () => {
    const grid = document.createElement('div');
    grid.id = 'bgGridOverlay';
    document.body.prepend(grid);

    ['bg-orb-1', 'bg-orb-2', 'bg-orb-3'].forEach(cls => {
      const orb = document.createElement('div');
      orb.className = 'bg-orb ' + cls;
      document.body.prepend(orb);
    });

    // Restore the person's "reduce motion" preference, if they set one before
    if (localStorage.getItem('reduceMotion') === 'true') {
      document.body.classList.add('reduce-motion');
    }
  });
})();

function toggleMotion() {
  document.body.classList.toggle('reduce-motion');
  const isReduced = document.body.classList.contains('reduce-motion');
  localStorage.setItem('reduceMotion', isReduced);

  const toggleSwitch = document.getElementById('motionToggleSwitch');
  if (toggleSwitch) {
    toggleSwitch.classList.toggle('active', !isReduced);
  }
}

// ---------- Top loading bar: auto-wraps every fetch() call on every page ----------
(function setupLoadingBar() {
  const bar = document.createElement('div');
  bar.id = 'topLoadingBar';
  document.addEventListener('DOMContentLoaded', () => document.body.prepend(bar));

  let activeRequests = 0;

  function showBar() {
    activeRequests++;
    const el = document.getElementById('topLoadingBar');
    if (el) el.classList.add('active');
  }

  function hideBar() {
    activeRequests = Math.max(0, activeRequests - 1);
    if (activeRequests === 0) {
      const el = document.getElementById('topLoadingBar');
      if (el) el.classList.remove('active');
    }
  }

  const originalFetch = window.fetch;
  window.fetch = function (...args) {
    showBar();
    return originalFetch.apply(this, args).finally(hideBar);
  };
})();

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
  const motionIsOn = !document.body.classList.contains('reduce-motion');

  document.getElementById('sidebar').innerHTML = `
    <div class="sidebar-brand"><i class="bi bi-cloud-fill"></i> CLOUD MANAGER</div>
    <div class="sidebar-links">${linksHtml}</div>
    <div class="sidebar-footer">
      <div class="theme-toggle" onclick="toggleMotion()">
        <span><i class="bi bi-stars"></i> Animations</span>
        <span class="theme-toggle-switch ${motionIsOn ? 'active' : ''}" id="motionToggleSwitch"></span>
      </div>
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

function enableTableSearch(inputId, tableBodyId) {
  const input = document.getElementById(inputId);
  if (!input) return;
  input.addEventListener('input', () => {
    const query = input.value.toLowerCase();
    document.querySelectorAll(`#${tableBodyId} tr`).forEach(row => {
      row.style.display = row.textContent.toLowerCase().includes(query) ? '' : 'none';
    });
  });
}

function enableCardSearch(inputId, containerId, cardSelector) {
  const input = document.getElementById(inputId);
  if (!input) return;
  input.addEventListener('input', () => {
    const query = input.value.toLowerCase();
    document.querySelectorAll(`#${containerId} ${cardSelector}`).forEach(card => {
      card.style.display = card.textContent.toLowerCase().includes(query) ? '' : 'none';
    });
  });
}