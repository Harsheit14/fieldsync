import type { Request, Response } from 'express';
import { ZodError } from 'zod';

import { syncOperationSchema } from '../schemas/sync.schema.js';
import { SyncService } from '../services/sync.service.js';
import { SurveyNotFoundError } from '../services/survey.errors.js';

const syncService = new SyncService();

export async function processSyncOperation(
    req: Request,


    res: Response,
): Promise<void> {
    try {
        const operation = syncOperationSchema.parse(req.body);

        const result = await syncService.process(operation);

        res.status(200).json(result);
    } catch (error) {
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

        if (error instanceof SurveyNotFoundError) {
            res.status(404).json({
                success: false,
                error: {
                    code: 'SURVEY_NOT_FOUND',
                    message: error.message,
                },
            });
            return;
        }

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