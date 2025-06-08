const sqlite3 = require('sqlite3').verbose();
const assert = require('assert');

// Helper to run SQL statements returning a promise
function run(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function all(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

describe('Balance period calculations', function () {
  let db;
  before(async function () {
    db = new sqlite3.Database(':memory:');
    await run(
      db,
      `CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER,
        type TEXT,
        document_date TEXT,
        total_amount REAL
      )`
    );    const now = new Date();
    const iso = (d) => d.toISOString().slice(0, 10);
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);

    // Yesterday's transactions (should be in this month but not today)
    await run(db, 'INSERT INTO documents (store_id,type,document_date,total_amount) VALUES (1,?,?,?)', [
      'purchase',
      iso(yesterday),
      100,
    ]);
    await run(db, 'INSERT INTO documents (store_id,type,document_date,total_amount) VALUES (1,?,?,?)', [
      'sale',
      iso(yesterday),
      40,
    ]);
    // Today's transactions
    await run(db, 'INSERT INTO documents (store_id,type,document_date,total_amount) VALUES (1,?,?,?)', [
      'purchase',
      iso(now),
      80,
    ]);
    await run(db, 'INSERT INTO documents (store_id,type,document_date,total_amount) VALUES (1,?,?,?)', [
      'sale',
      iso(now),
      20,
    ]);
    // Last month's transaction (should not be in this month)
    await run(db, 'INSERT INTO documents (store_id,type,document_date,total_amount) VALUES (1,?,?,?)', [
      'purchase',
      iso(lastMonth),
      50,
    ]);
  });

  after(function () {
    db.close();
  });

  it('computes correct balances for this month and today', async function () {
    const docs = await all(db, 'SELECT * FROM documents');
    const now = new Date();
    const thisMonth = {
      start: new Date(now.getFullYear(), now.getMonth(), 1),
      end: new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59),
    };
    const today = {
      start: new Date(now.getFullYear(), now.getMonth(), now.getDate()),
      end: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59),
    };    const docsThisMonth = docs.filter((d) => {
      // Parse date as YYYY-MM-DD format without timezone conversion
      const dateStr = d.document_date;
      const [year, month, day] = dateStr.split('-').map(Number);
      const date = new Date(year, month - 1, day); // month is 0-indexed
      return date >= thisMonth.start && date <= thisMonth.end;
    });

    const docsToday = docs.filter((d) => {
      // Parse date as YYYY-MM-DD format without timezone conversion
      const dateStr = d.document_date;
      const [year, month, day] = dateStr.split('-').map(Number);
      const date = new Date(year, month - 1, day); // month is 0-indexed
      return date >= today.start && date <= today.end;
    });

    function calc(list) {
      const inflows = list
        .filter((d) => d.type === 'purchase')
        .reduce((s, d) => s + (d.total_amount || 0), 0);
      const outflows = list
        .filter((d) => d.type === 'sale')
        .reduce((s, d) => s + (d.total_amount || 0), 0);
      return {
        inflows,
        outflows,
        balance: inflows - outflows,
      };
    }    const monthResult = calc(docsThisMonth);
    const todayResult = calc(docsToday);

    // This month: yesterday (100-40=60) + today (80-20=60) = 120
    assert.strictEqual(monthResult.balance, 120);
    // Today: only today's transactions (80-20=60)
    assert.strictEqual(todayResult.balance, 60);
  });
});
