import express from 'express';
import cors from 'cors';

import { syncRouter } from './routes/sync.routes.js';

export const app = express();

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
