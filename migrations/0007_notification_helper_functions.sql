-- =====================================================
-- NOTIFICATION SYSTEM: Helper Functions
-- =====================================================

-- Helper: Get all student IDs from group IDs
CREATE OR REPLACE FUNCTION get_students_in_groups(group_ids UUID[])
RETURNS TABLE(student_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT se.student_id
  FROM student_enrollments se
  WHERE se.group_id = ANY(group_ids)
    AND se.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Helper: Create notification for a user
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type VARCHAR,
  p_title VARCHAR,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, body, data)
  VALUES (p_user_id, p_type, p_title, p_body, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

