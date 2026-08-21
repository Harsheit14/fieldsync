import { withTransaction } from '../config/database.js';
import { SurveyRepository } from '../repositories/survey.repository.js';
import { SyncOperationRepository } from '../repositories/sync-operation.repository.js';
import { SurveyNotFoundError } from './survey.errors.js';
import type { SyncOperationInput } from '../schemas/sync.schema.js';

export interface SyncOperationResult {
  success: true;
  operationId: string;
  entityId: string;
  operationType: SyncOperationInput['operationType'];
}

export class SyncService {
  async process(
    operation: SyncOperationInput,
  ): Promise<SyncOperationResult> {
    return withTransaction(async (client): Promise<SyncOperationResult> => {
      const syncOperationRepository =
        new SyncOperationRepository(client);

      const surveyRepository = new SurveyRepository(client);

      /*
       * 1. Try to register the operation.
       *
       * operationId is our idempotency key.
       */
      const createdOperation =
        await syncOperationRepository.create({
          operationId: operation.operationId,
          entityType: operation.entityType,
          entityId: operation.entityId,
          operationType: operation.operationType,
        });

      /*
       * 2. Operation already exists.
       *
       * Return the previously stored response instead of
       * executing the operation again.
       */
      if (createdOperation === null) {
        const existingOperation =
          await syncOperationRepository.findByOperationId(
            operation.operationId,
          );

        if (existingOperation === null) {
          throw new Error(
            'Sync operation conflict could not be resolved.',
          );
        }

        if (
          existingOperation.status === 'completed' &&
          existingOperation.response !== null
        ) {
          return {
            success: true,
            operationId: existingOperation.operationId,
            entityId: existingOperation.entityId,
            operationType: existingOperation.operationType,
          };
        }

        throw new Error(
          `Sync operation '${operation.operationId}' is already being processed.`,
        );
      }

      /*
       * 3. Apply the survey mutation using the SAME
       * PostgreSQL transaction client.
       */
      switch (operation.operationType) {
        case 'create':
          await surveyRepository.create({
            ...operation.payload,
            id: operation.entityId,
          });
          break;

        case 'update': {
          const survey = await surveyRepository.update({
            ...operation.payload,
            id: operation.entityId,
          });

          if (survey === null) {
            throw new SurveyNotFoundError(operation.entityId);
          }

          break;
        }

        case 'delete': {
          const survey = await surveyRepository.delete(
            operation.entityId,
            operation.payload.updatedAt,
          );

          if (survey === null) {
            throw new SurveyNotFoundError(operation.entityId);
          }

          break;
        }
      }

      /*
       * 4. Build the successful response.
       */
      const response: SyncOperationResult = {
        success: true,
        operationId: operation.operationId,
        entityId: operation.entityId,
        operationType: operation.operationType,
      };

      /*
       * 5. Store the response in the idempotency table.
       *
       * This happens inside the SAME transaction as the
       * survey mutation.
       */
      await syncOperationRepository.markCompleted(
        operation.operationId,
        response,
      );

      return response;
    });
  }
}