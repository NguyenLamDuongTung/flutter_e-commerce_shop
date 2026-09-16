import mysql from 'mysql2/promise';

import { env } from './env.js';

export const database = mysql.createPool({
  host: env.database.host,
  port: env.database.port,
  user: env.database.user,
  password: env.database.password,
  database: env.database.name,

  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,

  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  decimalNumbers: true,
  timezone: 'Z',
});

export async function verifyDatabaseConnection() {
  const connection = await database.getConnection();

  try {
    await connection.query('SELECT 1');
    console.log('MySQL database connected.');
  } finally {
    connection.release();
  }
}