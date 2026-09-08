import { database } from '../config/database.js';
import type { PoolClient } from 'pg';

export interface SurveyRecord {
  id: string;
  farmerName: string;
  cropType: string;
  fieldArea: number;
  latitude: number;
  longitude: number;
  photoPaths: string[];
  status: string;
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateSurveyInput {
  id: string;
  farmerName: string;
  cropType: string;
  fieldArea: number;
  latitude: number;
  longitude: number;
  photoPaths: string[];
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface UpdateSurveyInput extends CreateSurveyInput {}

export type DatabaseClient = typeof database | PoolClient;

export type SurveyMutationResult =
  | {
      status: 'updated';
      survey: SurveyRecord;
    }
  | {
      status: 'not_found';
    }
  | {
      status: 'conflict';
      current: SurveyRecord;
    };

export type SurveyCreateResult =
  | {
      status: 'created';
      survey: SurveyRecord;
    }
  | {
      status: 'conflict';
      current: SurveyRecord;
    };

export class SurveyRepository {
  constructor(
    private readonly client: DatabaseClient = database,
  ) {}

  async create(
    input: CreateSurveyInput,
  ): Promise<SurveyCreateResult> {
    /*
     * Check whether this entity already exists.
     *
     * The entity UUID is the permanent identity of the survey.
     */
    const existingResult = await this.client.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [input.id],
    );

    if (existingResult.rows.length > 0) {
      return {
        status: 'conflict',
        current: this.toSurveyRecord(
          existingResult.rows[0],
        ),
      };
    }

    const result = await this.client.query(
      `
      INSERT INTO surveys (
        id,
        farmer_name,
        crop_type,
        field_area,
        latitude,
        longitude,
        photo_paths,
        status,
        created_at,
        updated_at
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7::jsonb,
        $8,
        $9,
        $10
      )
      RETURNING *
      `,
      [
        input.id,
        input.farmerName,
        input.cropType,
        input.fieldArea,
        input.latitude,
        input.longitude,
        JSON.stringify(input.photoPaths),
        input.status,
        input.createdAt,
        input.updatedAt,
      ],
    );

    return {
      status: 'created',
      survey: this.toSurveyRecord(result.rows[0]),
    };
  }

  async update(
    input: UpdateSurveyInput,
  ): Promise<SurveyMutationResult> {
    const existingResult = await this.client.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [input.id],
    );

    if (existingResult.rows.length === 0) {
      return {
        status: 'not_found',
      };
    }

    const existing = this.toSurveyRecord(
      existingResult.rows[0],
    );

    if (existing.isDeleted) {
      return {
        status: 'conflict',
        current: existing,
      };
    }

    if (input.updatedAt <= existing.updatedAt) {
      return {
        status: 'conflict',
        current: existing,
      };
    }

    const result = await this.client.query(
      `
      UPDATE surveys
      SET
        farmer_name = $2,
        crop_type = $3,
        field_area = $4,
        latitude = $5,
        longitude = $6,
        photo_paths = $7::jsonb,
        status = $8,
        updated_at = $9
      WHERE id = $1
        AND is_deleted = FALSE
        AND updated_at < $9
      RETURNING *
      `,
      [
        input.id,
        input.farmerName,
        input.cropType,
        input.fieldArea,
        input.latitude,
        input.longitude,
        JSON.stringify(input.photoPaths),
        input.status,
        input.updatedAt,
      ],
    );

    if (result.rows.length === 0) {
      const latestResult = await this.client.query(
        `
        SELECT *
        FROM surveys
        WHERE id = $1
        `,
        [input.id],
      );

      if (latestResult.rows.length === 0) {
        return {
          status: 'not_found',
        };
      }

      return {
        status: 'conflict',
        current: this.toSurveyRecord(
          latestResult.rows[0],
        ),
      };
    }

    return {
      status: 'updated',
      survey: this.toSurveyRecord(result.rows[0]),
    };
  }

  async delete(
    id: string,
    updatedAt: Date,
  ): Promise<SurveyMutationResult> {
    const existingResult = await this.client.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
      `,
      [id],
    );

    if (existingResult.rows.length === 0) {
      return {
        status: 'not_found',
      };
    }

    const existing = this.toSurveyRecord(
      existingResult.rows[0],
    );

    if (existing.isDeleted) {
      return {
        status: 'conflict',
        current: existing,
      };
    }

    if (updatedAt <= existing.updatedAt) {
      return {
        status: 'conflict',
        current: existing,
      };
    }

    const result = await this.client.query(
      `
      UPDATE surveys
      SET
        is_deleted = TRUE,
        updated_at = $2
      WHERE id = $1
        AND is_deleted = FALSE
        AND updated_at < $2
      RETURNING *
      `,
      [id, updatedAt],
    );

    if (result.rows.length === 0) {
      const latestResult = await this.client.query(
        `
        SELECT *
        FROM surveys
        WHERE id = $1
        `,
        [id],
      );

      if (latestResult.rows.length === 0) {
        return {
          status: 'not_found',
        };
      }

      return {
        status: 'conflict',
        current: this.toSurveyRecord(
          latestResult.rows[0],
        ),
      };
    }

    return {
      status: 'updated',
      survey: this.toSurveyRecord(result.rows[0]),
    };
  }

  async findById(
    id: string,
  ): Promise<SurveyRecord | null> {
    const result = await this.client.query(
      `
      SELECT *
      FROM surveys
      WHERE id = $1
        AND is_deleted = FALSE
      `,
      [id],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return this.toSurveyRecord(result.rows[0]);
  }

  private toSurveyRecord(
    row: Record<string, unknown>,
  ): SurveyRecord {
    return {
      id: row.id as string,
      farmerName: row.farmer_name as string,
      cropType: row.crop_type as string,
      fieldArea: row.field_area as number,
      latitude: row.latitude as number,
      longitude: row.longitude as number,
      photoPaths: row.photo_paths as string[],
      status: row.status as string,
      isDeleted: row.is_deleted as boolean,
      createdAt: row.created_at as Date,
      updatedAt: row.updated_at as Date,
    };
  }
}