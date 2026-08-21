CREATE TABLE IF NOT EXISTS surveys (
    id UUID PRIMARY KEY,

    farmer_name TEXT NOT NULL,
    crop_type TEXT NOT NULL,
    field_area DOUBLE PRECISION NOT NULL,

    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,

    photo_paths JSONB NOT NULL DEFAULT '[]'::jsonb,

    status TEXT NOT NULL,

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT surveys_field_area_positive
        CHECK (field_area > 0),

    CONSTRAINT surveys_latitude_valid
        CHECK (latitude >= -90 AND latitude <= 90),

    CONSTRAINT surveys_longitude_valid
        CHECK (longitude >= -180 AND longitude <= 180)
);

CREATE INDEX IF NOT EXISTS idx_surveys_updated_at
    ON surveys (updated_at);

CREATE INDEX IF NOT EXISTS idx_surveys_is_deleted
    ON surveys (is_deleted);

CREATE INDEX IF NOT EXISTS idx_surveys_status
    ON surveys (status);
