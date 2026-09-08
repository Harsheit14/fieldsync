import {
  SurveyRepository,
  type CreateSurveyInput,
  type SurveyRecord,
  type UpdateSurveyInput,
} from '../repositories/survey.repository.js';
import {
  SurveyConflictError,
  SurveyNotFoundError,
} from './survey.errors.js';

export class SurveyService {
  constructor(private readonly repository: SurveyRepository) {}

  async createSurvey(input: CreateSurveyInput): Promise<SurveyRecord> {
    const result = await this.repository.create(input);

    switch (result.status) {
      case 'created':
        return result.survey;

      case 'conflict':
        throw new SurveyConflictError(
          input.id,
          `Survey ${input.id} could not be created because a survey with this entity ID already exists.`,
        );
    }
  }

  async getSurvey(id: string): Promise<SurveyRecord> {
    const survey = await this.repository.findById(id);

    if (survey === null) {
      throw new SurveyNotFoundError(id);
    }

    return survey;
  }

  async updateSurvey(input: UpdateSurveyInput): Promise<SurveyRecord> {
    const result = await this.repository.update(input);

    switch (result.status) {
      case 'updated':
        return result.survey;

      case 'not_found':
        throw new SurveyNotFoundError(input.id);

      case 'conflict':
        throw new SurveyConflictError(
          input.id,
          `Survey ${input.id} could not be updated because a newer version already exists.`,
        );
    }
  }

  async deleteSurvey(
    id: string,
    updatedAt: Date,
  ): Promise<SurveyRecord> {
    const result = await this.repository.delete(id, updatedAt);

    switch (result.status) {
      case 'updated':
        return result.survey;

      case 'not_found':
        throw new SurveyNotFoundError(id);

      case 'conflict':
        throw new SurveyConflictError(
          id,
          `Survey ${id} could not be deleted because a newer version already exists or the survey was already deleted.`,
        );
    }
  }
}