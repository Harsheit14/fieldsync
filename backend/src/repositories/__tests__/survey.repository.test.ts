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
    await database.query('DELETE FROM surveys WHERE farmer_name = $1', [
      'Test Farmer',
    ]);
  });

  after(async () => {
    await database.query('DELETE FROM surveys WHERE farmer_name = $1', [
      'Test Farmer',
    ]);

    await database.end();
  });

  it('creates and retrieves a survey', async () => {
    const input = createInput();

    const created = await repository.create(input);

    assert.equal(created.id, input.id);
    assert.equal(created.farmerName, input.farmerName);
    assert.equal(created.cropType, input.cropType);
    assert.equal(created.fieldArea, input.fieldArea);
    assert.deepEqual(created.photoPaths, input.photoPaths);
    assert.equal(created.isDeleted, false);

    const found = await repository.findById(input.id);

    assert.ok(found);
    assert.equal(found.id, input.id);
    assert.equal(found.farmerName, input.farmerName);
    assert.deepEqual(found.photoPaths, input.photoPaths);
  });

  it('updates an existing survey', async () => {
    const input = createInput();

    await repository.create(input);

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

    assert.ok(updated);
    assert.equal(updated.id, input.id);
    assert.equal(updated.farmerName, 'Updated Farmer');
    assert.equal(updated.cropType, 'Rice');
    assert.equal(updated.fieldArea, 7.25);
    assert.deepEqual(updated.photoPaths, [
      '/photos/field-1.jpg',
      '/photos/field-2.jpg',
    ]);
    assert.equal(updated.createdAt.getTime(), input.createdAt.getTime());
    assert.equal(updated.updatedAt.getTime(), updatedAt.getTime());
  });

  it('soft deletes a survey', async () => {
    const input = createInput();

    await repository.create(input);

    const deletedAt = new Date(Date.now() + 1000);

    const deleted = await repository.delete(input.id, deletedAt);

    assert.ok(deleted);
    assert.equal(deleted.id, input.id);
    assert.equal(deleted.isDeleted, true);

    const found = await repository.findById(input.id);

    assert.equal(found, null);
  });

  it('does not update a deleted survey', async () => {
    const input = createInput();

    await repository.create(input);
    await repository.delete(input.id, new Date());

    const result = await repository.update({
      ...input,
      farmerName: 'Should Not Update',
      updatedAt: new Date(),
    });

    assert.equal(result, null);
  });

  it('returns null when updating a non-existent survey', async () => {
    const input = createInput();

    const result = await repository.update(input);

    assert.equal(result, null);
  });

  it('returns null when deleting a non-existent survey', async () => {
    const result = await repository.delete(randomUUID(), new Date());

    assert.equal(result, null);
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
