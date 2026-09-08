import { database } from '../config/database.js';
import type { PoolClient } from 'pg';

export interface SyncOperationRecord {
  operationId: string;
  entityType: string;
  entityId: string;
  operationType: 'create' | 'update' | 'delete';
  status: 'processing' | 'completed' | 'failed';
  response: unknown;
  createdAt: Date;
  completedAt: Date | null;
}

export interface CreateSyncOperationInput {
  operationId: string;
  entityType: string;
  entityId: string;
  operationType: 'create' | 'update' | 'delete';
}

export type DatabaseClient = typeof database | PoolClient;

export class SyncOperationRepository {
  constructor(
    private readonly client: DatabaseClient = database,
  ) {}

  async findByOperationId(
    operationId: string,
  ): Promise<SyncOperationRecord | null> {
    const result = await this.client.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return this.toRecord(result.rows[0]);
  }

  async create(
    input: CreateSyncOperationInput,
  ): Promise<SyncOperationRecord | null> {
    const result = await this.client.query(
      `
      INSERT INTO sync_operations (
        operation_id,
        entity_type,
        entity_id,
        operation_type,
        status
      )
      VALUES ($1, $2, $3, $4, 'processing')
      ON CONFLICT (operation_id) DO NOTHING
      RETURNING *
      `,
      [
        input.operationId,
        input.entityType,
        input.entityId,
        input.operationType,
      ],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return this.toRecord(result.rows[0]);
  }

  async markCompleted(
    operationId: string,
    response: unknown,
  ): Promise<void> {
    await this.client.query(
      `
      UPDATE sync_operations
      SET
        status = 'completed',
        response = $2::jsonb,
        completed_at = NOW()
      WHERE operation_id = $1
      `,
      [operationId, JSON.stringify(response)],
    );
  }

  async markFailed(
    operationId: string,
    response: unknown,
  ): Promise<void> {
    await this.client.query(
      `
      UPDATE sync_operations
      SET
        status = 'failed',
        response = $2::jsonb,
        completed_at = NOW()
      WHERE operation_id = $1
      `,
      [operationId, JSON.stringify(response)],
    );
  }

  private toRecord(
    row: Record<string, unknown>,
  ): SyncOperationRecord {
    return {
      operationId: row.operation_id as string,
      entityType: row.entity_type as string,
      entityId: row.entity_id as string,
      operationType: row.operation_type as
        | 'create'
        | 'update'
        | 'delete',
      status: row.status as
        | 'processing'
        | 'completed'
        | 'failed',
      response: row.response,
      createdAt: row.created_at as Date,
      completedAt: row.completed_at as Date | null,
    };
  }
}