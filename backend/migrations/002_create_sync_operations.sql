CREATE TABLE IF NOT EXISTS sync_operations (
    operation_id UUID PRIMARY KEY,

    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    operation_type TEXT NOT NULL,

    status TEXT NOT NULL,

    response JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    CONSTRAINT sync_operations_status_valid
        CHECK (status IN ('processing', 'completed', 'failed')),

    CONSTRAINT sync_operations_operation_type_valid
        CHECK (operation_type IN ('create', 'update', 'delete'))
);

CREATE INDEX IF NOT EXISTS idx_sync_operations_entity
    ON sync_operations (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_sync_operations_created_at
    ON sync_operations (created_at);
