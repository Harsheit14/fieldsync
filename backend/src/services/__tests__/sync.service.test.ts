import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { randomUUID } from 'node:crypto';

import { database } from '../../config/database.js';
import { SyncService } from '../sync.service.js';

const service = new SyncService();

describe('SyncService idempotency', () => {
  before(async () => {
    await database.query(
      `
      DELETE FROM sync_operations
      WHERE entity_id IN (
        SELECT id
        FROM surveys
        WHERE farmer_name = $1
      )
      `,
      ['Idempotency Test Farmer'],
    );

    await database.query(
      'DELETE FROM surveys WHERE farmer_name = $1',
      ['Idempotency Test Farmer'],
    );
  });

  after(async () => {
    await database.query(
      `
      DELETE FROM sync_operations
      WHERE entity_id IN (
        SELECT id
        FROM surveys
        WHERE farmer_name = $1
      )
      `,
      ['Idempotency Test Farmer'],
    );

    await database.query(
      'DELETE FROM surveys WHERE farmer_name = $1',
      ['Idempotency Test Farmer'],
    );

    await database.end();
  });

  it('does not execute the same operation twice', async () => {
    const operationId = randomUUID();
    const entityId = randomUUID();
    const now = new Date();

    const operation = {
      operationId,
      entityType: 'Survey' as const,
      entityId,
      operationType: 'create' as const,
      payload: {
        id: entityId,
        farmerName: 'Idempotency Test Farmer',
        cropType: 'Wheat',
        fieldArea: 5,
        latitude: 28.6139,
        longitude: 77.209,
        photoPaths: [],
        status: 'active',
        createdAt: now,
        updatedAt: now,
      },
    };

    const firstResult = await service.process(operation);

    assert.equal(firstResult.success, true);

    if (!firstResult.success) {
      throw new Error('Expected first synchronization to succeed.');
    }

    const secondResult = await service.process(operation);

    assert.equal(secondResult.success, true);

    if (!secondResult.success) {
      throw new Error(
        'Expected duplicate synchronization to return success.',
      );
    }

    assert.deepEqual(secondResult, firstResult);

    const surveyResult = await database.query(
      `
      SELECT COUNT(*)::int AS count
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveyResult.rows[0].count, 1);

    const operationResult = await database.query(
      `
      SELECT COUNT(*)::int AS count
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    assert.equal(operationResult.rows[0].count, 1);

    const storedOperation = await database.query(
      `
      SELECT status
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    assert.equal(
      storedOperation.rows[0].status,
      'completed',
    );
  });
});