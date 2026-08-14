// setup-passwords.js
// ONE-TIME SCRIPT: gives every existing sample user a real, working password
// so we can test the login feature. We run this once, then never again.

const bcrypt = require('bcrypt');
const db = require('./db');

async function setupPasswords() {
  try {
    // We'll set every user's password to this same simple test password.
    // In real life each user would pick their own - this is just for testing.
    const testPassword = 'Test1234!';
    const hashedPassword = await bcrypt.hash(testPassword, 10);
    // The "10" above is the hashing "strength" - higher = slower but more secure.
    // 10 is a common, sensible default.

    const [result] = await db.query(
      'UPDATE Users SET password_hash = ?',
      [hashedPassword]
    );

    console.log(`✅ Updated ${result.affectedRows} users.`);
    console.log(`Every user's password is now: ${testPassword}`);
    console.log(`Try logging in as username "john.smith" with that password.`);
  } catch (error) {
    console.error('❌ Something went wrong:', error.message);
  } finally {
    process.exit();
  }
}

setupPasswords();