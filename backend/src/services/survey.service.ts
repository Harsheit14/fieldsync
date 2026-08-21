import {
  SurveyRepository,
  type CreateSurveyInput,
  type SurveyRecord,
  type UpdateSurveyInput,
} from '../repositories/survey.repository.js';

export class SurveyNotFoundError extends Error {
  constructor(id: string) {
    super(`Survey ${id} was not found.`);
    this.name = 'SurveyNotFoundError';
  }
}

export class SurveyService {
  constructor(private readonly repository: SurveyRepository) {}

  async createSurvey(input: CreateSurveyInput): Promise<SurveyRecord> {
    return this.repository.create(input);
  }

  async getSurvey(id: string): Promise<SurveyRecord> {
    const survey = await this.repository.findById(id);

    if (survey === null) {
      throw new SurveyNotFoundError(id);
    }

    return survey;
  }

  async updateSurvey(input: UpdateSurveyInput): Promise<SurveyRecord> {
    const survey = await this.repository.update(input);

    if (survey === null) {
      throw new SurveyNotFoundError(input.id);
    }

    return survey;
  }

  async deleteSurvey(id: string, updatedAt: Date): Promise<SurveyRecord> {
    const survey = await this.repository.delete(id, updatedAt);

    if (survey === null) {
      throw new SurveyNotFoundError(id);
    }

    return survey;
  }
}
