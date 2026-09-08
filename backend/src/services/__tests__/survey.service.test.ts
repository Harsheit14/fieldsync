import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import {
  SurveyRepository,
  type CreateSurveyInput,
  type SurveyRecord,
  type UpdateSurveyInput,
} from '../../repositories/survey.repository.js';

import {
  SurveyConflictError,
  SurveyNotFoundError,
} from '../survey.errors.js';

import { SurveyService } from '../survey.service.js';

class FakeSurveyRepository extends SurveyRepository {
  private readonly surveys = new Map<string, SurveyRecord>();

  override async create(
    input: CreateSurveyInput,
  ) {
    const existing = this.surveys.get(input.id);

    if (existing !== undefined) {
      return {
        status: 'conflict' as const,
        current: existing,
      };
    }

    const survey: SurveyRecord = {
      ...input,
      isDeleted: false,
    };

    this.surveys.set(survey.id, survey);

    return {
      status: 'created' as const,
      survey,
    };
  }

  override async findById(
    id: string,
  ): Promise<SurveyRecord | null> {
    const survey = this.surveys.get(id);

    if (survey === undefined || survey.isDeleted) {
      return null;
    }

    return survey;
  }

  override async update(
    input: UpdateSurveyInput,
  ) {
    const existing = this.surveys.get(input.id);

    if (existing === undefined) {
      return {
        status: 'not_found' as const,
      };
    }

    if (existing.isDeleted) {
      return {
        status: 'conflict' as const,
        current: existing,
      };
    }

    if (input.updatedAt <= existing.updatedAt) {
      return {
        status: 'conflict' as const,
        current: existing,
      };
    }

    const updated: SurveyRecord = {
      ...existing,
      ...input,
      isDeleted: false,
    };

    this.surveys.set(updated.id, updated);

    return {
      status: 'updated' as const,
      survey: updated,
    };
  }

  override async delete(
    id: string,
    updatedAt: Date,
  ) {
    const existing = this.surveys.get(id);

    if (existing === undefined) {
      return {
        status: 'not_found' as const,
      };
    }

    if (existing.isDeleted) {
      return {
        status: 'conflict' as const,
        current: existing,
      };
    }

    if (updatedAt <= existing.updatedAt) {
      return {
        status: 'conflict' as const,
        current: existing,
      };
    }

    const deleted: SurveyRecord = {
      ...existing,
      isDeleted: true,
      updatedAt,
    };

    this.surveys.set(id, deleted);

    return {
      status: 'updated' as const,
      survey: deleted,
    };
  }
}

function createInput(
  overrides: Partial<CreateSurveyInput> = {},
): CreateSurveyInput {
  const now = new Date();

  return {
    id: randomUUID(),
    farmerName: 'Test Farmer',
    cropType: 'Wheat',
    fieldArea: 5,
    latitude: 28.6139,
    longitude: 77.209,
    photoPaths: [],
    status: 'draft',
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

function createService(): SurveyService {
  return new SurveyService(new FakeSurveyRepository());
}

describe('SurveyService', () => {
  it('creates a survey', async () => {
    const service = createService();
    const input = createInput();

    const survey = await service.createSurvey(input);

    assert.equal(survey.id, input.id);
    assert.equal(survey.farmerName, input.farmerName);
    assert.equal(survey.isDeleted, false);
  });

  it('throws SurveyConflictError when creating a duplicate survey', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    await assert.rejects(
      () => service.createSurvey(input),
      SurveyConflictError,
    );
  });

  it('retrieves an existing survey', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    const survey = await service.getSurvey(input.id);

    assert.equal(survey.id, input.id);
    assert.equal(survey.cropType, 'Wheat');
  });

  it('throws SurveyNotFoundError when retrieving a missing survey', async () => {
    const service = createService();
    const id = randomUUID();

    await assert.rejects(
      () => service.getSurvey(id),
      SurveyNotFoundError,
    );
  });

  it('updates an existing survey', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    const updated = await service.updateSurvey({
      ...input,
      farmerName: 'Updated Farmer',
      cropType: 'Rice',
      updatedAt: new Date(Date.now() + 1000),
    });

    assert.equal(updated.id, input.id);
    assert.equal(updated.farmerName, 'Updated Farmer');
    assert.equal(updated.cropType, 'Rice');
  });

  it('throws SurveyNotFoundError when updating a missing survey', async () => {
    const service = createService();

    await assert.rejects(
      () => service.updateSurvey(createInput()),
      SurveyNotFoundError,
    );
  });

  it('throws SurveyConflictError for a stale update', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    await assert.rejects(
      () =>
        service.updateSurvey({
          ...input,
          farmerName: 'Stale Update',
          updatedAt: new Date(
            input.updatedAt.getTime() - 1000,
          ),
        }),
      SurveyConflictError,
    );
  });

  it('soft deletes an existing survey', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    const deleted = await service.deleteSurvey(
      input.id,
      new Date(input.updatedAt.getTime() + 1000),
    );

    assert.equal(deleted.id, input.id);
    assert.equal(deleted.isDeleted, true);

    await assert.rejects(
      () => service.getSurvey(input.id),
      SurveyNotFoundError,
    );
  });

  it('throws SurveyNotFoundError when deleting a missing survey', async () => {
    const service = createService();

    await assert.rejects(
      () => service.deleteSurvey(randomUUID(), new Date()),
      SurveyNotFoundError,
    );
  });

  it('throws SurveyConflictError when deleting with a stale timestamp', async () => {
    const service = createService();
    const input = createInput();

    await service.createSurvey(input);

    await assert.rejects(
      () =>
        service.deleteSurvey(
          input.id,
          new Date(input.updatedAt.getTime() - 1000),
        ),
      SurveyConflictError,
    );
  });
});