-- Create temp_attachments table for temporary file storage
CREATE TABLE IF NOT EXISTS temp_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    temp_id VARCHAR(255) UNIQUE NOT NULL, -- temp_xxx format
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(500) NOT NULL,
    file_path TEXT NOT NULL, -- Storage path
    file_url TEXT, -- Public URL if available
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    is_finalized BOOLEAN DEFAULT FALSE
);

-- Index for cleanup and lookup
CREATE INDEX idx_temp_attachments_user_id ON temp_attachments(user_id);
CREATE INDEX idx_temp_attachments_temp_id ON temp_attachments(temp_id);
CREATE INDEX idx_temp_attachments_expires_at ON temp_attachments(expires_at);
CREATE INDEX idx_temp_attachments_finalized ON temp_attachments(is_finalized);

-- Add RLS policies
ALTER TABLE temp_attachments ENABLE ROW LEVEL SECURITY;

-- Users can only access their own temp attachments
CREATE POLICY "Users can manage own temp attachments" ON temp_attachments
    FOR ALL USING (auth.uid() = user_id);

-- Auto-cleanup expired temp attachments (runs every hour)
CREATE OR REPLACE FUNCTION cleanup_expired_temp_attachments()
RETURNS void AS $$
BEGIN
    DELETE FROM temp_attachments 
    WHERE expires_at < NOW() 
    AND is_finalized = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run cleanup (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-temp-attachments', '0 * * * *', 'SELECT cleanup_expired_temp_attachments();');
