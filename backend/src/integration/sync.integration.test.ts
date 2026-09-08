import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { randomUUID } from 'node:crypto';

import request from 'supertest';

import { app } from '../app.js';
import { database } from '../config/database.js';

describe('Sync API integration', () => {
  before(async () => {
    await database.query('DELETE FROM sync_operations');
    await database.query('DELETE FROM surveys');
  });

  after(async () => {
    await database.query('DELETE FROM sync_operations');
    await database.query('DELETE FROM surveys');
    await database.end();
  });

  it('processes a survey create operation end-to-end', async () => {
    const operationId = randomUUID();
    const entityId = randomUUID();

    const createdAt = new Date();
    const updatedAt = new Date(createdAt.getTime());

    const payload = {
      id: entityId,
      farmerName: 'Integration Farmer',
      cropType: 'Wheat',
      fieldArea: 5.5,
      latitude: 28.6139,
      longitude: 77.209,
      photoPaths: ['/photos/integration.jpg'],
      status: 'draft',
      createdAt: createdAt.toISOString(),
      updatedAt: updatedAt.toISOString(),
    };

    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId,
        entityType: 'Survey',
        entityId,
        operationType: 'create',
        payload,
      })
      .expect('Content-Type', /json/)
      .expect(200);

    assert.equal(response.body.success, true);

    const surveyResult = await database.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveyResult.rows.length, 1);

    const survey = surveyResult.rows[0];

    assert.equal(survey.id, entityId);
    assert.equal(survey.farmer_name, 'Integration Farmer');
    assert.equal(survey.crop_type, 'Wheat');
    assert.equal(survey.field_area, 5.5);
    assert.equal(survey.is_deleted, false);

    const operationResult = await database.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    assert.equal(operationResult.rows.length, 1);

    const operation = operationResult.rows[0];

    assert.equal(operation.operation_id, operationId);
    assert.equal(operation.entity_type, 'Survey');
    assert.equal(operation.entity_id, entityId);
    assert.equal(operation.operation_type, 'create');
    assert.equal(operation.status, 'completed');
    assert.ok(operation.completed_at);
    assert.ok(operation.response);
  });

  it('returns the existing result for a duplicate operation', async () => {
    const operationId = randomUUID();
    const entityId = randomUUID();

    const timestamp = new Date().toISOString();

    const payload = {
      id: entityId,
      farmerName: 'Idempotency Farmer',
      cropType: 'Rice',
      fieldArea: 3.25,
      latitude: 28.6139,
      longitude: 77.209,
      photoPaths: [],
      status: 'draft',
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    const requestBody = {
      operationId,
      entityType: 'Survey',
      entityId,
      operationType: 'create',
      payload,
    };

    const first = await request(app)
      .post('/api/sync')
      .send(requestBody)
      .expect(200);

    assert.equal(first.body.success, true);

    const second = await request(app)
      .post('/api/sync')
      .send(requestBody)
      .expect(200);

    assert.equal(second.body.success, true);
    assert.deepEqual(second.body, first.body);

    const surveys = await database.query(
      `
      SELECT COUNT(*)::int AS count
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveys.rows[0].count, 1);

    const operations = await database.query(
      `
      SELECT COUNT(*)::int AS count
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    assert.equal(operations.rows[0].count, 1);
  });

  it('processes a survey update operation end-to-end', async () => {
    const entityId = randomUUID();

    const createdAt = new Date();
    const originalUpdatedAt = new Date(
      createdAt.getTime(),
    );

    const createOperationId = randomUUID();

    const createPayload = {
      id: entityId,
      farmerName: 'Update Farmer',
      cropType: 'Wheat',
      fieldArea: 4.5,
      latitude: 28.6139,
      longitude: 77.209,
      photoPaths: ['/photos/original.jpg'],
      status: 'draft',
      createdAt: createdAt.toISOString(),
      updatedAt: originalUpdatedAt.toISOString(),
    };

    await request(app)
      .post('/api/sync')
      .send({
        operationId: createOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'create',
        payload: createPayload,
      })
      .expect(200);

    const updateOperationId = randomUUID();
    const updatedAt = new Date(
      originalUpdatedAt.getTime() + 1000,
    );

    const updatePayload = {
      id: entityId,
      farmerName: 'Updated Farmer',
      cropType: 'Rice',
      fieldArea: 7.25,
      latitude: 29.1,
      longitude: 78.2,
      photoPaths: [
        '/photos/original.jpg',
        '/photos/updated.jpg',
      ],
      status: 'active',
      createdAt: createdAt.toISOString(),
      updatedAt: updatedAt.toISOString(),
    };

    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId: updateOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'update',
        payload: updatePayload,
      })
      .expect('Content-Type', /json/)
      .expect(200);

    assert.equal(response.body.success, true);
    assert.equal(
      response.body.operationType,
      'update',
    );

    const surveyResult = await database.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveyResult.rows.length, 1);

    const survey = surveyResult.rows[0];

    assert.equal(survey.farmer_name, 'Updated Farmer');
    assert.equal(survey.crop_type, 'Rice');
    assert.equal(survey.field_area, 7.25);
    assert.equal(survey.status, 'active');
    assert.equal(survey.is_deleted, false);

    const operationResult = await database.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [updateOperationId],
    );

    assert.equal(operationResult.rows.length, 1);
    assert.equal(
      operationResult.rows[0].status,
      'completed',
    );
  });

  it('processes a survey delete operation end-to-end', async () => {
    const entityId = randomUUID();

    const createdAt = new Date();
    const originalUpdatedAt = new Date(
      createdAt.getTime(),
    );

    const createOperationId = randomUUID();

    const createPayload = {
      id: entityId,
      farmerName: 'Delete Farmer',
      cropType: 'Wheat',
      fieldArea: 6,
      latitude: 28.6139,
      longitude: 77.209,
      photoPaths: [],
      status: 'active',
      createdAt: createdAt.toISOString(),
      updatedAt: originalUpdatedAt.toISOString(),
    };

    await request(app)
      .post('/api/sync')
      .send({
        operationId: createOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'create',
        payload: createPayload,
      })
      .expect(200);

    const deleteOperationId = randomUUID();
    const deleteUpdatedAt = new Date(
      originalUpdatedAt.getTime() + 1000,
    );

    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId: deleteOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'delete',
        payload: {
          updatedAt: deleteUpdatedAt.toISOString(),
        },
      })
      .expect('Content-Type', /json/)
      .expect(200);

    assert.equal(response.body.success, true);
    assert.equal(
      response.body.operationType,
      'delete',
    );

    const surveyResult = await database.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveyResult.rows.length, 1);
    assert.equal(
      surveyResult.rows[0].is_deleted,
      true,
    );

    const operationResult = await database.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [deleteOperationId],
    );

    assert.equal(operationResult.rows.length, 1);
    assert.equal(
      operationResult.rows[0].status,
      'completed',
    );
  });

  it('returns 404 and records a failed operation when updating a missing survey', async () => {
    const operationId = randomUUID();
    const entityId = randomUUID();

    const timestamp = new Date().toISOString();

    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId,
        entityType: 'Survey',
        entityId,
        operationType: 'update',
        payload: {
          id: entityId,
          farmerName: 'Missing Farmer',
          cropType: 'Wheat',
          fieldArea: 4,
          latitude: 28.6139,
          longitude: 77.209,
          photoPaths: [],
          status: 'active',
          createdAt: timestamp,
          updatedAt: timestamp,
        },
      })
      .expect('Content-Type', /json/)
      .expect(404);

    assert.equal(response.body.success, false);
    assert.equal(
      response.body.error.code,
      'SURVEY_NOT_FOUND',
    );

    const operationResult = await database.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [operationId],
    );

    assert.equal(operationResult.rows.length, 1);
    assert.equal(
      operationResult.rows[0].status,
      'failed',
    );
  });

  it('rejects a stale update with a 409 conflict', async () => {
    const entityId = randomUUID();

    const createdAt = new Date();
    const initialUpdatedAt = new Date(
      createdAt.getTime(),
    );

    const createOperationId = randomUUID();

    await request(app)
      .post('/api/sync')
      .send({
        operationId: createOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'create',
        payload: {
          id: entityId,
          farmerName: 'Original Farmer',
          cropType: 'Wheat',
          fieldArea: 5,
          latitude: 28.6139,
          longitude: 77.209,
          photoPaths: [],
          status: 'draft',
          createdAt: createdAt.toISOString(),
          updatedAt: initialUpdatedAt.toISOString(),
        },
      })
      .expect(200);

    const newerUpdatedAt = new Date(
      initialUpdatedAt.getTime() + 2000,
    );

    await request(app)
      .post('/api/sync')
      .send({
        operationId: randomUUID(),
        entityType: 'Survey',
        entityId,
        operationType: 'update',
        payload: {
          id: entityId,
          farmerName: 'Newer Farmer',
          cropType: 'Rice',
          fieldArea: 8,
          latitude: 29,
          longitude: 78,
          photoPaths: [],
          status: 'active',
          createdAt: createdAt.toISOString(),
          updatedAt: newerUpdatedAt.toISOString(),
        },
      })
      .expect(200);

    const staleOperationId = randomUUID();

    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId: staleOperationId,
        entityType: 'Survey',
        entityId,
        operationType: 'update',
        payload: {
          id: entityId,
          farmerName: 'Stale Farmer',
          cropType: 'Maize',
          fieldArea: 2,
          latitude: 27,
          longitude: 77,
          photoPaths: [],
          status: 'stale',
          createdAt: createdAt.toISOString(),
          updatedAt: initialUpdatedAt.toISOString(),
        },
      })
      .expect('Content-Type', /json/)
      .expect(409);

    assert.equal(response.body.success, false);
    assert.equal(
      response.body.error.code,
      'SURVEY_CONFLICT',
    );

    const surveyResult = await database.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [entityId],
    );

    assert.equal(surveyResult.rows.length, 1);
    assert.equal(
      surveyResult.rows[0].farmer_name,
      'Newer Farmer',
    );
    assert.equal(
      surveyResult.rows[0].crop_type,
      'Rice',
    );
    assert.equal(
      surveyResult.rows[0].is_deleted,
      false,
    );

    const operationResult = await database.query(
      `
      SELECT *
      FROM sync_operations
      WHERE operation_id = $1
      `,
      [staleOperationId],
    );

    assert.equal(operationResult.rows.length, 1);
    assert.equal(
      operationResult.rows[0].status,
      'failed',
    );
  });

  it('rejects an invalid sync request', async () => {
    const response = await request(app)
      .post('/api/sync')
      .send({
        operationId: 'not-a-uuid',
        entityType: 'Survey',
        entityId: randomUUID(),
        operationType: 'create',
        payload: {},
      })
      .expect('Content-Type', /json/);

    assert.ok(response.status >= 400);
    assert.equal(response.body.success, false);
  });

  it('serves the health endpoint', async () => {
    const response = await request(app)
      .get('/api/health')
      .expect(200);

    assert.equal(response.body.success, true);
    assert.equal(response.body.service, 'fieldsync-api');
    assert.equal(response.body.status, 'healthy');
  });
});