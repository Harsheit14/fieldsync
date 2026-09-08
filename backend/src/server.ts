import 'dotenv/config';

import { app } from './app.js';
import { checkDatabaseConnection } from './config/database.js';
import { env } from './config/env.js';

async function bootstrap(): Promise<void> {
  try {
    await checkDatabaseConnection();

    console.log('✓ PostgreSQL connection successful');
    console.log(`✓ Connected to database: ${env.DATABASE_NAME}`);

    app.listen(env.PORT, () => {
      console.log(`✓ FieldSync API listening on port ${env.PORT}`);
    });
  } catch (error) {
    console.error('✗ PostgreSQL connection failed:', error);
    process.exit(1);
  }
}

void bootstrap();
