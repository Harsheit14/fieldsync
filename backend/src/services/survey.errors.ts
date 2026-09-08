export class SurveyNotFoundError extends Error {
  constructor(id: string) {
    super(`Survey '${id}' was not found.`);
    this.name = 'SurveyNotFoundError';
  }
}

export class SurveyConflictError extends Error {
  constructor(
    id: string,
    message = `Survey '${id}' has been modified or deleted by another operation.`,
  ) {
    super(message);
    this.name = 'SurveyConflictError';
  }
}