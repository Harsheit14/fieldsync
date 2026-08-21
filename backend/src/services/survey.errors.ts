export class SurveyNotFoundError extends Error {
  constructor(id: string) {
    super(`Survey '${id}' was not found.`);
    this.name = 'SurveyNotFoundError';
  }
}