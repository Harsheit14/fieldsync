import { z } from 'zod';

const surveyPayloadSchema = z.object({
  id: z.string().uuid(),
  farmerName: z.string().min(1),
  cropType: z.string().min(1),
  fieldArea: z.number().positive(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  photoPaths: z.array(z.string()),
  status: z.string().min(1),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export const syncOperationSchema = z.object({
  operationId: z.string().uuid(),
  entityType: z.literal('Survey'),
  entityId: z.string().uuid(),
  operationType: z.enum(['create', 'update', 'delete']),
  payload: surveyPayloadSchema,
});

export type SyncOperationInput = z.infer<typeof syncOperationSchema>;
