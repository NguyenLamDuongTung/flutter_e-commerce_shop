import app from './app.js';
import { env } from './config/env.js';
import { verifyDatabaseConnection } from './config/database.js';

async function startServer() {
  try {
    await verifyDatabaseConnection();

    app.listen(env.port, '0.0.0.0', () => {
      console.log(
        `Flutter Shop API running on http://localhost:${env.port}`,
      );
    });
  } catch (error) {
    console.error('Unable to start the API:', error);
    process.exit(1);
  }
}

startServer();