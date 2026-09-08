import type { Request, Response } from 'express';
import { ZodError } from 'zod';

import { syncOperationSchema } from '../schemas/sync.schema.js';
import { SyncService } from '../services/sync.service.js';

const syncService = new SyncService();

export async function processSyncOperation(
  req: Request,
  res: Response,
): Promise<void> {
  try {
    const operation = syncOperationSchema.parse(req.body);

    const result = await syncService.process(operation);

    /*
     * Expected business failure.
     *
     * The transaction has already committed the failed
     * sync operation, so we can safely return the HTTP error.
     */
    if (!result.success) {
      if (result.error.code === 'SURVEY_NOT_FOUND') {
        res.status(404).json(result);
        return;
      }

      if (result.error.code === 'SURVEY_CONFLICT') {
        res.status(409).json(result);
        return;
      }
    }

    res.status(200).json(result);
  } catch (error) {
    /*
     * Request validation failure.
     */
    if (error instanceof ZodError) {
      res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid synchronization operation.',
          details: error.issues,
        },
      });
      return;
    }

    /*
     * Unexpected errors reach here.
     *
     * The database transaction has already rolled back.
     */
    console.error('Sync operation failed:', error);

    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Synchronization operation failed.',
      },
    });
  }
}