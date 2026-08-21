import 'dotenv/config';

import express from 'express';
import cors from 'cors';

import { checkDatabaseConnection } from './config/database.js';
import { env } from './config/env.js';
import { syncRouter } from './routes/sync.routes.js';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    service: 'fieldsync-api',
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', syncRouter);

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