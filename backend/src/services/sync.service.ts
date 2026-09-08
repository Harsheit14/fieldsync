import { withTransaction } from '../config/database.js';
import { SurveyRepository } from '../repositories/survey.repository.js';
import { SyncOperationRepository } from '../repositories/sync-operation.repository.js';
import type { SyncOperationInput } from '../schemas/sync.schema.js';

export type SyncOperationSuccess = {
  success: true;
  operationId: string;
  entityId: string;
  operationType: SyncOperationInput['operationType'];
};

export type SyncOperationFailure = {
  success: false;
  operationId: string;
  entityId: string;
  operationType: SyncOperationInput['operationType'];
  error: {
    code: 'SURVEY_NOT_FOUND' | 'SURVEY_CONFLICT';
    message: string;
  };
};

export type SyncOperationResult =
  | SyncOperationSuccess
  | SyncOperationFailure;

export class SyncService {
  async process(
    operation: SyncOperationInput,
  ): Promise<SyncOperationResult> {
    return withTransaction(async (client) => {
      const syncOperationRepository =
        new SyncOperationRepository(client);

      const surveyRepository =
        new SurveyRepository(client);

      /*
       * Register the operation using operationId as the
       * idempotency key.
       */
      const createdOperation =
        await syncOperationRepository.create({
          operationId: operation.operationId,
          entityType: operation.entityType,
          entityId: operation.entityId,
          operationType: operation.operationType,
        });

      /*
       * Idempotency handling.
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

        /*
         * Already completed successfully.
         */
        if (
          existingOperation.status === 'completed' &&
          existingOperation.response !== null
        ) {
          return existingOperation.response as SyncOperationSuccess;
        }

        /*
         * Previously failed.
         *
         * Return the stored failure without executing
         * the mutation again.
         */
        if (
          existingOperation.status === 'failed' &&
          existingOperation.response !== null
        ) {
          return existingOperation.response as SyncOperationFailure;
        }

        /*
         * Another request is currently processing this
         * operation.
         */
        throw new Error(
          `Sync operation '${operation.operationId}' is already being processed.`,
        );
      }

      /*
       * Apply the requested mutation.
       *
       * Expected business failures are converted into
       * structured results. They do NOT throw, allowing
       * the transaction to commit the failed operation.
       */
      switch (operation.operationType) {
        case 'create': {
          const result = await surveyRepository.create({
            ...operation.payload,
            id: operation.entityId,
          });

          if (result.status === 'conflict') {
            const failure: SyncOperationFailure = {
              success: false,
              operationId: operation.operationId,
              entityId: operation.entityId,
              operationType: operation.operationType,
              error: {
                code: 'SURVEY_CONFLICT',
                message:
                  `Survey ${operation.entityId} could not be created because a survey with this entity ID already exists.`,
              },
            };

            await syncOperationRepository.markFailed(
              operation.operationId,
              failure,
            );

            return failure;
          }

          break;
        }

        case 'update': {
          const result = await surveyRepository.update({
            ...operation.payload,
            id: operation.entityId,
          });

          if (result.status === 'not_found') {
            const failure: SyncOperationFailure = {
              success: false,
              operationId: operation.operationId,
              entityId: operation.entityId,
              operationType: operation.operationType,
              error: {
                code: 'SURVEY_NOT_FOUND',
                message:
                  `Survey '${operation.entityId}' was not found.`,
              },
            };

            await syncOperationRepository.markFailed(
              operation.operationId,
              failure,
            );

            return failure;
          }

          if (result.status === 'conflict') {
            const failure: SyncOperationFailure = {
              success: false,
              operationId: operation.operationId,
              entityId: operation.entityId,
              operationType: operation.operationType,
              error: {
                code: 'SURVEY_CONFLICT',
                message:
                  `Survey ${operation.entityId} could not be updated because a newer version already exists or the survey was already deleted.`,
              },
            };

            await syncOperationRepository.markFailed(
              operation.operationId,
              failure,
            );

            return failure;
          }

          break;
        }

        case 'delete': {
          const result = await surveyRepository.delete(
            operation.entityId,
            operation.payload.updatedAt,
          );

          if (result.status === 'not_found') {
            const failure: SyncOperationFailure = {
              success: false,
              operationId: operation.operationId,
              entityId: operation.entityId,
              operationType: operation.operationType,
              error: {
                code: 'SURVEY_NOT_FOUND',
                message:
                  `Survey '${operation.entityId}' was not found.`,
              },
            };

            await syncOperationRepository.markFailed(
              operation.operationId,
              failure,
            );

            return failure;
          }

          if (result.status === 'conflict') {
            const failure: SyncOperationFailure = {
              success: false,
              operationId: operation.operationId,
              entityId: operation.entityId,
              operationType: operation.operationType,
              error: {
                code: 'SURVEY_CONFLICT',
                message:
                  `Survey ${operation.entityId} could not be deleted because a newer version already exists or the survey was already deleted.`,
              },
            };

            await syncOperationRepository.markFailed(
              operation.operationId,
              failure,
            );

            return failure;
          }

          break;
        }
      }

      /*
       * Successful mutation.
       */
      const response: SyncOperationSuccess = {
        success: true,
        operationId: operation.operationId,
        entityId: operation.entityId,
        operationType: operation.operationType,
      };

      /*
       * Store the successful response in the SAME
       * transaction as the survey mutation.
       */
      await syncOperationRepository.markCompleted(
        operation.operationId,
        response,
      );

      return response;
    });
  }
}