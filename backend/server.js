// server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const db = require('./db');

const app = express();

app.use(cors());
app.use(express.json());

// ---------- LOGIN ----------
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    const [rows] = await db.query(
      `SELECT u.user_id, u.username, u.email, u.full_name, u.org_id,
              u.password_hash, u.mfa_enabled,
              ur.role_name, ast.status_name
       FROM Users u
       JOIN UserRoles ur ON u.role_id = ur.role_id
       JOIN AccountStatuses ast ON u.status_id = ast.status_id
       WHERE u.username = ?`,
      [username]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = rows[0];
    const passwordMatches = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    if (user.status_name !== 'Active') {
      return res.status(403).json({ error: `Account is ${user.status_name}` });
    }

    delete user.password_hash; // never send the hash back to the browser
    res.json(user);

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// ---------- ORGANIZATIONS ----------
app.get('/api/organizations', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT o.org_id, o.org_name, o.industry, o.country, o.email,
              cs.size_name
       FROM Organizations o
       LEFT JOIN CompanySizes cs ON o.size_id = cs.size_id
       ORDER BY o.org_name`
    );
    res.json(rows);
  } catch (error) {
    console.error('Organizations error:', error);
    res.status(500).json({ error: 'Failed to load organizations' });
  }
});

// ---------- PLANS ----------
app.get('/api/plans', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT sp.plan_id, sp.plan_name, sp.monthly_price, sp.annual_price, sp.max_users,
              st.type_name AS service_type,
              pt.tier_name AS plan_tier,
              sl.level_name AS support_level
       FROM SubscriptionPlans sp
       JOIN ServiceTypes st ON sp.service_type_id = st.service_type_id
       JOIN PlanTiers pt ON sp.tier_id = pt.tier_id
       JOIN SupportLevels sl ON sp.support_level_id = sl.support_level_id
       ORDER BY st.type_name, pt.tier_id`
    );
    res.json(rows);
  } catch (error) {
    console.error('Plans error:', error);
    res.status(500).json({ error: 'Failed to load plans' });
  }
});

// ---------- SUBSCRIPTIONS (uses the view from database.sql) ----------
app.get('/api/subscriptions', async (req, res) => {
  try {
    const [rows] = await db.query(`SELECT * FROM vw_ActiveSubscriptions`);
    res.json(rows);
  } catch (error) {
    console.error('Subscriptions error:', error);
    res.status(500).json({ error: 'Failed to load subscriptions' });
  }
});

// ---------- RESOURCE HEALTH (uses the view from database.sql) ----------
app.get('/api/resource-health', async (req, res) => {
  try {
    const [rows] = await db.query(`SELECT * FROM vw_ResourceHealth`);
    res.json(rows);
  } catch (error) {
    console.error('Resource health error:', error);
    res.status(500).json({ error: 'Failed to load resource health' });
  }
});

// ---------- BILLING (uses the view from database.sql) ----------
app.get('/api/billing', async (req, res) => {
  try {
    const [rows] = await db.query(`SELECT * FROM vw_BillingDashboard ORDER BY invoice_date DESC`);
    res.json(rows);
  } catch (error) {
    console.error('Billing error:', error);
    res.status(500).json({ error: 'Failed to load billing data' });
  }
});

// ---------- USERS ----------
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.user_id, u.username, u.email, u.full_name, u.mfa_enabled, u.created_at,
              ur.role_name, ast.status_name, o.org_name
       FROM Users u
       JOIN UserRoles ur ON u.role_id = ur.role_id
       JOIN AccountStatuses ast ON u.status_id = ast.status_id
       LEFT JOIN Organizations o ON u.org_id = o.org_id
       ORDER BY u.user_id`
    );
    res.json(rows);
  } catch (error) {
    console.error('Users error:', error);
    res.status(500).json({ error: 'Failed to load users' });
  }
});

// ---------- REPORTS: revenue by service ----------
app.get('/api/reports/revenue-by-service', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT st.type_name AS service_type,
              COUNT(DISTINCT us.subscription_id) AS active_subscriptions,
              SUM(CASE WHEN bc.months_count = 1 THEN sp.monthly_price ELSE sp.annual_price / 12 END) AS monthly_revenue
       FROM UserSubscriptions us
       JOIN SubscriptionPlans sp ON us.plan_id = sp.plan_id
       JOIN ServiceTypes st ON sp.service_type_id = st.service_type_id
       JOIN BillingCycles bc ON us.cycle_id = bc.cycle_id
       JOIN SubscriptionStatuses ss ON us.sub_status_id = ss.sub_status_id
       WHERE ss.status_name = 'Active'
       GROUP BY st.type_name`
    );
    res.json(rows);
  } catch (error) {
    console.error('Reports error:', error);
    res.status(500).json({ error: 'Failed to load revenue report' });
  }
});

// ---------- DASHBOARD STATS ----------
app.get('/api/dashboard-stats', async (req, res) => {
  try {
    const [[{ total_users }]] = await db.query(`SELECT COUNT(*) AS total_users FROM Users`);
    const [[{ active_subscriptions }]] = await db.query(
      `SELECT COUNT(*) AS active_subscriptions FROM UserSubscriptions us
       JOIN SubscriptionStatuses ss ON us.sub_status_id = ss.sub_status_id
       WHERE ss.status_name = 'Active'`
    );
    const [[{ total_resources }]] = await db.query(`SELECT COUNT(*) AS total_resources FROM Resources`);
    const [[{ open_tickets }]] = await db.query(
      `SELECT COUNT(*) AS open_tickets FROM SupportTickets st
       JOIN TicketStatuses ts ON st.ticket_status_id = ts.ticket_status_id
       WHERE ts.status_name IN ('Open','InProgress')`
    );
    const [[{ monthly_revenue }]] = await db.query(
      `SELECT COALESCE(SUM(
         CASE WHEN bc.months_count = 1 THEN sp.monthly_price ELSE sp.annual_price / 12 END
       ), 0) AS monthly_revenue
       FROM UserSubscriptions us
       JOIN SubscriptionPlans sp ON us.plan_id = sp.plan_id
       JOIN BillingCycles bc ON us.cycle_id = bc.cycle_id
       JOIN SubscriptionStatuses ss ON us.sub_status_id = ss.sub_status_id
       WHERE ss.status_name = 'Active'`
    );

    res.json({ total_users, active_subscriptions, total_resources, open_tickets, monthly_revenue });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to load dashboard stats' });
  }
});

// ============================================================
// RESOURCES
// ============================================================

// ---------- GET: list all resources ----------
app.get('/api/resources', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT r.resource_id, r.resource_name,
              rt.type_name AS resource_type, rt.type_category,
              rs.status_name AS status,
              r.region, r.ip_address,
              u.username, o.org_name
       FROM Resources r
       JOIN ResourceTypes rt ON r.resource_type_id = rt.resource_type_id
       JOIN ResourceStatuses rs ON r.res_status_id = rs.res_status_id
       JOIN Users u ON r.user_id = u.user_id
       LEFT JOIN Organizations o ON u.org_id = o.org_id
       ORDER BY r.resource_id`
    );
    res.json(rows);
  } catch (error) {
    console.error('Resources error:', error);
    res.status(500).json({ error: 'Failed to load resources' });
  }
});

// ---------- GET: dropdown options for the "New Resource" form ----------
app.get('/api/resource-options', async (req, res) => {
  try {
    const [types] = await db.query(
      `SELECT resource_type_id, type_name FROM ResourceTypes ORDER BY type_name`
    );
    const [subscriptions] = await db.query(
      `SELECT us.subscription_id, u.username, sp.plan_name
       FROM UserSubscriptions us
       JOIN Users u ON us.user_id = u.user_id
       JOIN SubscriptionPlans sp ON us.plan_id = sp.plan_id
       JOIN SubscriptionStatuses ss ON us.sub_status_id = ss.sub_status_id
       WHERE ss.status_name = 'Active'
       ORDER BY u.username`
    );
    res.json({ types, subscriptions });
  } catch (error) {
    console.error('Resource options error:', error);
    res.status(500).json({ error: 'Failed to load resource options' });
  }
});

// ---------- POST: create a resource ----------
app.post('/api/resources', async (req, res) => {
  const { resource_name, resource_type_id, subscription_id, region, ip_address } = req.body;

  if (!resource_name || !resource_type_id || !subscription_id) {
    return res.status(400).json({ error: 'Resource name, type, and subscription are required' });
  }

  try {
    // The owner (user_id) is derived from the chosen subscription
    const [subRows] = await db.query(
      `SELECT user_id FROM UserSubscriptions WHERE subscription_id = ?`,
      [subscription_id]
    );
    if (subRows.length === 0) {
      return res.status(400).json({ error: 'Selected subscription not found' });
    }
    const user_id = subRows[0].user_id;

    const [statusRows] = await db.query(
      `SELECT res_status_id FROM ResourceStatuses WHERE status_name = 'Pending' LIMIT 1`
    );
    const res_status_id = statusRows[0].res_status_id;

    await db.query(
      `INSERT INTO Resources
         (subscription_id, user_id, resource_type_id, res_status_id, resource_name, region, ip_address)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [subscription_id, user_id, resource_type_id, res_status_id, resource_name, region || null, ip_address || null]
    );

    res.json({ message: 'Resource created' });
  } catch (error) {
    console.error('Create resource error:', error);
    res.status(500).json({ error: 'Failed to create resource' });
  }
});

// ---------- PUT: update a resource's status ----------
app.put('/api/resources/:id/status', async (req, res) => {
  const { status_name } = req.body;

  try {
    const [statusRows] = await db.query(
      `SELECT res_status_id FROM ResourceStatuses WHERE status_name = ?`,
      [status_name]
    );
    if (statusRows.length === 0) {
      return res.status(400).json({ error: `Invalid status: ${status_name}` });
    }

    await db.query(
      `UPDATE Resources SET res_status_id = ? WHERE resource_id = ?`,
      [statusRows[0].res_status_id, req.params.id]
    );

    res.json({ message: 'Resource status updated' });
  } catch (error) {
    console.error('Update resource status error:', error);
    res.status(500).json({ error: 'Failed to update resource status' });
  }
});

// ---------- DELETE: remove a resource ----------
app.delete('/api/resources/:id', async (req, res) => {
  try {
    await db.query(`DELETE FROM Resources WHERE resource_id = ?`, [req.params.id]);
    res.json({ message: 'Resource deleted' });
  } catch (error) {
    // ResourceUsage and SupportTickets both reference resource_id, so MySQL
    // blocks the delete with a foreign key error if usage history or tickets exist.
    if (error.code === 'ER_ROW_IS_REFERENCED_2' || error.code === 'ER_ROW_IS_REFERENCED') {
      return res.status(400).json({ error: 'This resource has usage history or linked tickets and cannot be deleted.' });
    }
    console.error('Delete resource error:', error);
    res.status(500).json({ error: 'Failed to delete resource' });
  }
});

// ============================================================
// TICKETS
// ============================================================

// ---------- GET: list all tickets ----------
app.get('/api/tickets', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT t.ticket_id, t.ticket_number,
              u.username,
              r.resource_name,
              tc.category_name AS category,
              pl.priority_name AS priority,
              ts.status_name AS status,
              t.subject, t.created_at,
              DATEDIFF(COALESCE(t.resolved_at, NOW()), t.created_at) AS days_open
       FROM SupportTickets t
       JOIN Users u ON t.user_id = u.user_id
       LEFT JOIN Resources r ON t.resource_id = r.resource_id
       JOIN TicketCategories tc ON t.category_id = tc.category_id
       JOIN PriorityLevels pl ON t.priority_id = pl.priority_id
       JOIN TicketStatuses ts ON t.ticket_status_id = ts.ticket_status_id
       ORDER BY t.created_at DESC`
    );
    res.json(rows);
  } catch (error) {
    console.error('Tickets error:', error);
    res.status(500).json({ error: 'Failed to load tickets' });
  }
});

// ---------- GET: dropdown options for the "New Ticket" form ----------
app.get('/api/ticket-options', async (req, res) => {
  try {
    const [categories] = await db.query(
      `SELECT category_id, category_name FROM TicketCategories ORDER BY category_name`
    );
    const [priorities] = await db.query(
      `SELECT priority_id, priority_name FROM PriorityLevels ORDER BY priority_rank`
    );
    const [resources] = await db.query(
      `SELECT resource_id, resource_name FROM Resources ORDER BY resource_name`
    );
    res.json({ categories, priorities, resources });
  } catch (error) {
    console.error('Ticket options error:', error);
    res.status(500).json({ error: 'Failed to load ticket options' });
  }
});

// ---------- POST: create a ticket ----------
app.post('/api/tickets', async (req, res) => {
  const { user_id, category_id, priority_id, resource_id, subject } = req.body;

  if (!user_id || !category_id || !priority_id || !subject) {
    return res.status(400).json({ error: 'User, category, priority, and subject are required' });
  }

  try {
    const [statusRows] = await db.query(
      `SELECT ticket_status_id FROM TicketStatuses WHERE status_name = 'Open' LIMIT 1`
    );
    const ticket_status_id = statusRows[0].ticket_status_id;

    const [[{ ticket_count }]] = await db.query(`SELECT COUNT(*) AS ticket_count FROM SupportTickets`);
    const ticket_number = `TKT-${String(ticket_count + 1).padStart(3, '0')}`;

    await db.query(
      `INSERT INTO SupportTickets
         (user_id, resource_id, category_id, priority_id, ticket_status_id, ticket_number, subject)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [user_id, resource_id || null, category_id, priority_id, ticket_status_id, ticket_number, subject]
    );

    res.json({ message: 'Ticket created', ticket_number });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({ error: 'Failed to create ticket' });
  }
});

// ---------- PUT: update a ticket's status ----------
app.put('/api/tickets/:id/status', async (req, res) => {
  const { status_name } = req.body;

  try {
    const [statusRows] = await db.query(
      `SELECT ticket_status_id FROM TicketStatuses WHERE status_name = ?`,
      [status_name]
    );
    if (statusRows.length === 0) {
      return res.status(400).json({ error: `Invalid status: ${status_name}` });
    }

    // Mark resolved_at when moved into Resolved/Closed, clear it if reopened
    const resolvedAt = (status_name === 'Resolved' || status_name === 'Closed') ? new Date() : null;

    await db.query(
      `UPDATE SupportTickets SET ticket_status_id = ?, resolved_at = ? WHERE ticket_id = ?`,
      [statusRows[0].ticket_status_id, resolvedAt, req.params.id]
    );

    res.json({ message: 'Ticket status updated' });
  } catch (error) {
    console.error('Update ticket status error:', error);
    res.status(500).json({ error: 'Failed to update ticket status' });
  }
});

// ---------- DELETE: remove a ticket ----------
app.delete('/api/tickets/:id', async (req, res) => {
  try {
    await db.query(`DELETE FROM SupportTickets WHERE ticket_id = ?`, [req.params.id]);
    res.json({ message: 'Ticket deleted' });
  } catch (error) {
    console.error('Delete ticket error:', error);
    res.status(500).json({ error: 'Failed to delete ticket' });
  }
});

// ---------- START SERVER ----------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});