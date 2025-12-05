-- Add startTime and endTime columns to Track table
ALTER TABLE "Track" ADD COLUMN IF NOT EXISTS "startTime" TIMESTAMP(3) NOT NULL DEFAULT '2025-12-02 09:00:00';
ALTER TABLE "Track" ADD COLUMN IF NOT EXISTS "endTime" TIMESTAMP(3) NOT NULL DEFAULT '2025-12-02 18:00:00';

-- Copy existing day values to startTime and calculate endTime
UPDATE "Track" SET
  "startTime" = "day",
  "endTime" = "day" + INTERVAL '8 hours'
WHERE "startTime" = '2025-12-02 09:00:00';
