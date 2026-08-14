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

// ---------- START SERVER ----------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});