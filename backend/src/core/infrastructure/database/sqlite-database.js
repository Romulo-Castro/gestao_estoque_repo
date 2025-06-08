// Core Infrastructure - Database Implementation
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class SQLiteDatabase {
    constructor() {
        this.db = null;
        this.dbPath = process.env.DB_PATH || path.join(__dirname, '../../../../database.db');
    }

    async connect() {
        return new Promise((resolve, reject) => {
            this.db = new sqlite3.Database(this.dbPath, (err) => {
                if (err) {
                    console.error('Database connection error:', err);
                    reject(err);
                } else {
                    console.log('Connected to SQLite database');
                    this.enableForeignKeys();
                    resolve();
                }
            });
        });
    }

    enableForeignKeys() {
        this.db.run('PRAGMA foreign_keys = ON');
    }

    async close() {
        return new Promise((resolve, reject) => {
            if (this.db) {
                this.db.close((err) => {
                    if (err) reject(err);
                    else resolve();
                });
            } else {
                resolve();
            }
        });
    }

    async run(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.run(sql, params, function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve({
                        lastID: this.lastID,
                        changes: this.changes
                    });
                }
            });
        });
    }

    async get(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.get(sql, params, (err, row) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    async all(sql, params = []) {
        return new Promise((resolve, reject) => {
            this.db.all(sql, params, (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }

    async beginTransaction() {
        return this.run('BEGIN TRANSACTION');
    }

    async commit() {
        return this.run('COMMIT');
    }

    async rollback() {
        return this.run('ROLLBACK');
    }

    async executeInTransaction(operations) {
        await this.beginTransaction();
        try {
            const results = [];
            for (const operation of operations) {
                const result = await operation();
                results.push(result);
            }
            await this.commit();
            return results;
        } catch (error) {
            await this.rollback();
            throw error;
        }
    }
}

module.exports = SQLiteDatabase;
