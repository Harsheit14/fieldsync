import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { randomUUID } from 'node:crypto';

import { database } from '../../config/database.js';
import {
  SurveyRepository,
  type CreateSurveyInput,
} from '../survey.repository.js';

const repository = new SurveyRepository();

const createInput = (
  overrides: Partial<CreateSurveyInput> = {},
): CreateSurveyInput => {
  const now = new Date();

  return {
    id: randomUUID(),
    farmerName: 'Test Farmer',
    cropType: 'Wheat',
    fieldArea: 4.5,
    latitude: 28.6139,
    longitude: 77.209,
    photoPaths: ['/photos/field-1.jpg'],
    status: 'draft',
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
};

describe('SurveyRepository', () => {
  before(async () => {
    await database.query(
      'DELETE FROM surveys WHERE farmer_name = $1',
      ['Test Farmer'],
    );
  });

  after(async () => {
    await database.query(
      'DELETE FROM surveys WHERE farmer_name = $1',
      ['Test Farmer'],
    );

    await database.end();
  });

  it('creates and retrieves a survey', async () => {
    const input = createInput();

    const result = await repository.create(input);

    assert.equal(result.status, 'created');

    if (result.status !== 'created') {
      throw new Error('Expected survey to be created.');
    }

    const created = result.survey;

    assert.equal(created.id, input.id);
    assert.equal(created.farmerName, input.farmerName);
    assert.equal(created.cropType, input.cropType);
    assert.equal(created.fieldArea, input.fieldArea);
    assert.deepEqual(
      created.photoPaths,
      input.photoPaths,
    );
    assert.equal(created.isDeleted, false);

    const found = await repository.findById(input.id);

    assert.ok(found);
    assert.equal(found.id, input.id);
    assert.equal(found.farmerName, input.farmerName);
    assert.deepEqual(
      found.photoPaths,
      input.photoPaths,
    );
  });

  it('rejects duplicate survey creation', async () => {
    const input = createInput();

    const first = await repository.create(input);

    assert.equal(first.status, 'created');

    const second = await repository.create(input);

    assert.equal(second.status, 'conflict');

    if (second.status !== 'conflict') {
      throw new Error('Expected duplicate creation conflict.');
    }

    assert.equal(second.current.id, input.id);
    assert.equal(
      second.current.farmerName,
      input.farmerName,
    );
  });

  it('updates an existing survey', async () => {
    const input = createInput();

    const createdResult = await repository.create(input);

    assert.equal(createdResult.status, 'created');

    const updatedAt = new Date(Date.now() + 1000);

    const updated = await repository.update({
      ...input,
      farmerName: 'Updated Farmer',
      cropType: 'Rice',
      fieldArea: 7.25,
      photoPaths: [
        '/photos/field-1.jpg',
        '/photos/field-2.jpg',
      ],
      updatedAt,
    });

    assert.equal(updated.status, 'updated');

    if (updated.status !== 'updated') {
      throw new Error('Expected survey to be updated.');
    }

    assert.equal(updated.survey.id, input.id);
    assert.equal(
      updated.survey.farmerName,
      'Updated Farmer',
    );
    assert.equal(updated.survey.cropType, 'Rice');
    assert.equal(updated.survey.fieldArea, 7.25);

    assert.deepEqual(updated.survey.photoPaths, [
      '/photos/field-1.jpg',
      '/photos/field-2.jpg',
    ]);

    assert.equal(
      updated.survey.createdAt.getTime(),
      input.createdAt.getTime(),
    );

    assert.equal(
      updated.survey.updatedAt.getTime(),
      updatedAt.getTime(),
    );
  });

  it('soft deletes a survey', async () => {
    const input = createInput();

    const createdResult = await repository.create(input);

    assert.equal(createdResult.status, 'created');

    const deletedAt = new Date(Date.now() + 1000);

    const deleted = await repository.delete(
      input.id,
      deletedAt,
    );

    assert.equal(deleted.status, 'updated');

    if (deleted.status !== 'updated') {
      throw new Error('Expected survey to be deleted.');
    }

    assert.equal(deleted.survey.id, input.id);
    assert.equal(deleted.survey.isDeleted, true);

    const found = await repository.findById(input.id);

    assert.equal(found, null);
  });

  it('does not update a deleted survey', async () => {
    const input = createInput();

    const createdResult = await repository.create(input);

    assert.equal(createdResult.status, 'created');

    await repository.delete(
      input.id,
      new Date(Date.now() + 1000),
    );

    const result = await repository.update({
      ...input,
      farmerName: 'Should Not Update',
      updatedAt: new Date(Date.now() + 2000),
    });

    assert.equal(result.status, 'conflict');
  });

  it('returns not_found when updating a non-existent survey', async () => {
    const input = createInput();

    const result = await repository.update(input);

    assert.equal(result.status, 'not_found');
  });

  it('returns not_found when deleting a non-existent survey', async () => {
    const result = await repository.delete(
      randomUUID(),
      new Date(),
    );

    assert.equal(result.status, 'not_found');
  });

  it('rejects stale updates', async () => {
    const input = createInput();

    const createdResult = await repository.create(input);

    assert.equal(createdResult.status, 'created');

    const newerTimestamp = new Date(
      input.updatedAt.getTime() + 1000,
    );

    const updated = await repository.update({
      ...input,
      farmerName: 'Newer Farmer',
      updatedAt: newerTimestamp,
    });

    assert.equal(updated.status, 'updated');

    const stale = await repository.update({
      ...input,
      farmerName: 'Stale Farmer',
      updatedAt: input.updatedAt,
    });

    assert.equal(stale.status, 'conflict');

    if (stale.status !== 'conflict') {
      throw new Error('Expected stale update conflict.');
    }

    assert.equal(
      stale.current.farmerName,
      'Newer Farmer',
    );
  });

  it('rejects stale deletes', async () => {
    const input = createInput();

    const createdResult = await repository.create(input);

    assert.equal(createdResult.status, 'created');

    const newerTimestamp = new Date(
      input.updatedAt.getTime() + 1000,
    );

    const updated = await repository.update({
      ...input,
      farmerName: 'Newer Farmer',
      updatedAt: newerTimestamp,
    });

    assert.equal(updated.status, 'updated');

    const staleDelete = await repository.delete(
      input.id,
      input.updatedAt,
    );

    assert.equal(staleDelete.status, 'conflict');

    const found = await repository.findById(input.id);

    assert.ok(found);
    assert.equal(found.farmerName, 'Newer Farmer');
    assert.equal(found.isDeleted, false);
  });

  it('enforces survey database constraints', async () => {
    const input = createInput({
      fieldArea: -1,
    });

    await assert.rejects(
      () => repository.create(input),
      /surveys_field_area_positive/,
    );
  });
});