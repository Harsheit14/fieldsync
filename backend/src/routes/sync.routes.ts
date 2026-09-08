import { Router } from 'express';

import { processSyncOperation } from '../controllers/sync.controller.js';

export const syncRouter = Router();

syncRouter.post('/sync', processSyncOperation);
