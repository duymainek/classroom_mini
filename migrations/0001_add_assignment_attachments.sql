-- Create assignment_attachments table
CREATE TABLE assignment_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER, -- in bytes
    file_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies for assignment_attachments
ALTER TABLE assignment_attachments ENABLE ROW LEVEL SECURITY;

-- Policy: Instructors can manage attachments for their own assignments
CREATE POLICY "Allow instructors to manage attachments for their assignments"
ON assignment_attachments
FOR ALL
USING (
  (get_my_claim('user_role'::text)) = '"instructor"'::jsonb AND
  EXISTS (
    SELECT 1 FROM assignments
    WHERE assignments.id = assignment_attachments.assignment_id
    AND assignments.instructor_id = auth.uid()
  )
);

-- Policy: Students can view attachments for assignments in their groups
CREATE POLICY "Allow students to view attachments for their assignments"
ON assignment_attachments
FOR SELECT
USING (
  (get_my_claim('user_role'::text)) = '"student"'::jsonb AND
  EXISTS (
    SELECT 1 FROM assignments a
    JOIN assignment_groups ag ON a.id = ag.assignment_id
    JOIN student_enrollments se ON ag.group_id = se.group_id
    WHERE a.id = assignment_attachments.assignment_id
    AND se.student_id = auth.uid()
  )
);
