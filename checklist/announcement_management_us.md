# ANNOUNCEMENT MANAGEMENT - PRODUCT BACKLOG

## 📝 NOTES & DEPENDENCIES

### Pre-requisites
- [ ] **Check existing database schema** (use Cursor + Supabase MCP)
  - Verify tables: users, semesters, courses, groups, students
  - Understand existing relationships
  - Align new announcement tables with current structure

### Design System Reference
- Follow UX_DESIGN_RECOMMENDATIONS.md guidelines:
  - 8px spacing grid
  - Mobile-first (focus mobile only)
  - Touch targets minimum 44px
  - Progressive disclosure
  - Visual hierarchy với typography
  - Real-time validation
  - Smooth animations

---

## 🎯 EPIC: ANNOUNCEMENT MANAGEMENT FOR INSTRUCTOR

### Goal
Enable instructors to create, publish, manage announcements and track student engagement.

### Success Metrics
- Instructors can publish announcements in < 2 minutes
- Students receive announcements based on group scope
- Instructors can track who viewed/downloaded materials
- Comments enable quick Q&A between instructor and students

---

## 📋 USER STORIES - PHASE 1: CORE CRUD

### Story 1.1: Create and Publish Announcement
**As an** Instructor  
**I want to** create and publish an announcement with title, content, and files  
**So that** I can communicate important information to my students

**Acceptance Criteria:**
1. Form có 3 sections: Basic Info, Attachments, Scope
2. **Basic Info:**
   - Title field: required, max 200 characters, show character counter
   - Content field: rich text editor, required, min 10 characters
   - Helper text: "Share important information with students"
3. **Attachments (optional):**
   - "Attach Files" button
   - Can select multiple files (max 5 files)
   - Each file max 10MB
   - Allowed formats: PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, TXT, ZIP, JPG, PNG
   - Show preview: file name, size, icon, remove button
   - Show error if invalid file type or size exceeded
4. **Scope Selection (required):**
   - 3 options: "One group", "Multiple groups", "All groups"
   - Default selected: "All groups"
   - If "One group": show dropdown with list of groups
   - If "Multiple groups": show multi-select with list of groups
   - If "All groups": show info text "(X students)"
   - Each group shows: name + student count
5. **Actions:**
   - Cancel button: close form, don't save
   - Publish button: validate, confirm, publish
6. **Validation:**
   - Title required
   - Content required, min 10 chars
   - Scope required (must select at least 1 group or all)
   - Show inline error messages
7. **Confirmation before publish:**
   - Dialog showing: title, scope summary, file count
   - "Are you sure?" message
   - Cancel / Confirm buttons
8. **After publish:**
   - Success message: "Announcement published successfully"
   - Close form, return to announcements list
   - New announcement appears at top of list

**Business Rules:**
- Only instructor can create announcements
- Must belong to a course in current semester
- Scope cannot be changed after published
- All content must relate to IT topics (Faculty requirement)

**UI Notes:**
- Use bottom sheet for mobile
- Follow 8px spacing grid
- Touch targets 44px minimum
- Show loading state during publish
- Smooth animations when opening/closing

---

### Story 1.2: View List of Announcements
**As an** Instructor  
**I want to** see all announcements I've created in a course  
**So that** I can manage and monitor them

**Acceptance Criteria:**
1. **Location:** Announcements appear in "Stream" tab of Course Space
2. **Top Bar:**
   - Title: "Stream"
   - "+" button: creates new announcement
3. **Filter/Sort Bar:**
   - Filter dropdown: "All Groups" or filter by specific group
   - Sort dropdown: "Newest" (default) or "Oldest"
4. **List Display:**
   - Each announcement shown as card
   - Card shows:
     - 📢 icon + Title (bold, prominent)
     - Published time (relative: "2 hours ago", "Yesterday", "Jan 15")
     - Scope info: "Sent to: Group 1" or "Sent to: All groups"
     - Content preview: first 150 characters + "..."
     - Bottom icons:
       - 📎 X files (if has attachments)
       - 👁 Y views
       - 💬 Z comments
     - 3-dot menu: Edit, Delete
5. **Interactions:**
   - Tap card: open detail view
   - Tap "+": open create form
   - Pull to refresh: reload list
   - Scroll: load more (pagination)
6. **Empty State:**
   - Show when no announcements
   - Message: "No announcements yet"
   - Button: "Create your first one!"
7. **Filter Logic:**
   - Filter by group: only show announcements for selected group
   - Sort newest: most recent first
   - Sort oldest: oldest first
   - Filters persist when navigating away

**Business Rules:**
- Only show announcements of current course
- When switch semester, load announcements of that semester
- Show announcements regardless of scope (instructor sees all)

**UI Notes:**
- Cards have 16px horizontal margin, 8px vertical margin
- Card internal padding: 16px
- Icons use 8px spacing between them
- Loading skeleton while fetching data

---

### Story 1.3: View Announcement Detail
**As an** Instructor  
**I want to** view full details of an announcement  
**So that** I can see content, files, comments and tracking stats

**Acceptance Criteria:**
1. **Header:**
   - Back button (top-left)
   - Title: announcement title (truncated if long)
   - 3-dot menu: Edit, Delete
2. **Content Sections (scrollable):**
   
   **A. Main Content:**
   - 📢 icon + Title (large, bold)
   - Meta info: "Published: Jan 15, 2025 at 2:30 PM"
   - Scope info: "Sent to: Group 1, Group 2" or "All groups"
   - Full content (render rich text with formatting)
   - Divider line
   
   **B. Attachments (if any):**
   - Label: "Attachments"
   - Each file as card: icon + name + size
   - Tap file: download or preview (if image)
   
   **C. Stats:**
   - "👁 35/50 students viewed" button → opens tracking
   - "📥 Download statistics" button (if has files) → opens tracking
   
   **D. Comments:**
   - Label: "Comments (5)"
   - Comment input box (for instructor):
     - Avatar + placeholder "Add a comment..."
     - Max 500 characters, show counter
     - Post button
   - Comments list:
     - Show all comments, newest first
     - Each comment: avatar, name, role badge (instructor), text, time
     - Reply button on each comment
     - Replies indented (threaded display)
   - Load more button if >10 comments

3. **Interactions:**
   - Tap Edit: open edit form
   - Tap Delete: show confirmation dialog
   - Tap tracking buttons: open tracking modals
   - Tap file: trigger download, track download
   - Post comment: add to list immediately
   - Reply to comment: show reply input under that comment

**Business Rules:**
- Instructor can edit/delete their own announcements
- Comments visible to all students in scope
- Download tracking only for files

**UI Notes:**
- Follow spacing: 16px padding, 24px section gaps
- Use Material cards for files and comments
- Smooth scroll behavior
- Show loading when posting comment

---

### Story 1.4: Edit Announcement
**As an** Instructor  
**I want to** edit an announcement I published  
**So that** I can correct mistakes or update information

**Acceptance Criteria:**
1. **Access:** Tap "Edit" from detail view or list 3-dot menu
2. **Form:** Same layout as create form
3. **Pre-filled Data:**
   - Title: current value
   - Content: current value (with formatting)
   - Files: show current files with remove option
   - Scope: displayed but **grayed out** (read-only)
4. **Can Modify:**
   - Title
   - Content
   - Add new files (within limit)
   - Remove existing files
5. **Cannot Modify:**
   - Scope type
   - Group selection
6. **Scope Display:**
   - Show as read-only with info icon
   - Tooltip: "Scope cannot be changed after publishing"
7. **Actions:**
   - Cancel: close form, no changes
   - Save Changes: validate, confirm, save
8. **Confirmation:**
   - Dialog: "Save changes to this announcement?"
   - Show what changed (title/content/files)
   - Cancel / Save buttons
9. **After Save:**
   - Success message: "Announcement updated successfully"
   - Return to detail view with updated content
   - Show "Last edited: [timestamp]" badge on announcement

**Business Rules:**
- Scope CANNOT be changed after publish (hard requirement)
- Students see updated version immediately
- Track edit history (timestamp)
- Original published date unchanged

**UI Notes:**
- Scope section visually different (grayed background)
- Clear indication "Editing: [title]"
- Same validation as create form

---

### Story 1.5: Delete Announcement
**As an** Instructor  
**I want to** delete an announcement  
**So that** students no longer see outdated information

**Acceptance Criteria:**
1. **Access:** Tap "Delete" from detail view or list 3-dot menu
2. **Confirmation Dialog:**
   - Icon: ⚠️ warning (red)
   - Title: "Delete Announcement?"
   - Impact messages:
     - "This will remove it from all groups"
     - "Students will no longer see it"
     - "X files will be deleted" (if has files)
     - "Y comments will be lost" (if has comments)
   - Actions:
     - Cancel button (left, text)
     - Delete button (right, red, text)
3. **After Confirm:**
   - Show loading
   - Delete announcement
   - Success message: "Announcement deleted successfully"
   - Return to announcements list
   - Announcement removed from list
4. **Error Handling:**
   - If network error: show error, allow retry
   - If server error: show friendly message

**Business Rules:**
- Soft delete (mark as deleted, don't permanently remove from database)
- Associated files deleted from storage
- Comments deleted
- View/download tracking data retained for audit

**UI Notes:**
- Destructive action requires confirmation
- Clear consequences shown
- Red color for delete action (danger)

---

## 📋 USER STORIES - PHASE 2: FILES & SCOPE

### Story 2.1: Attach Files to Announcement
**As an** Instructor  
**I want to** attach multiple files to my announcement  
**So that** students can download reference materials

**Acceptance Criteria:**
1. **In Create/Edit Form:**
   - "Attach Files" button (outlined style, icon 📎)
   - Tap button: opens file picker
2. **File Picker:**
   - Allow multi-select
   - Support formats: PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, TXT, ZIP, JPG, PNG
3. **After Selection:**
   - Files added to preview list
   - Each file card shows:
     - File type icon (based on extension)
     - File name
     - File size (formatted: "2.5 MB")
     - Remove button (X icon)
4. **Validation:**
   - Max 5 files total
   - Max 10MB per file
   - Show error dialog if:
     - "Maximum 5 files allowed"
     - "File size exceeds 10MB limit"
     - "Invalid file format"
5. **Remove File:**
   - Tap X button: confirm removal
   - File removed from list immediately
6. **Upload:**
   - Files uploaded when announcement published
   - Show progress indicator during upload
   - If upload fails: show error, allow retry

**Business Rules:**
- Files optional, not required
- Files stored in secure storage
- Students can only download, not upload

**UI Notes:**
- File cards have 8px spacing between them
- Use appropriate icons per file type
- Show upload progress clearly

---

### Story 2.2: Select Announcement Scope
**As an** Instructor  
**I want to** choose which groups receive the announcement  
**So that** I can target the right audience

**Acceptance Criteria:**
1. **Scope Options (Radio buttons):**
   - ○ "One group"
   - ○ "Multiple groups"  
   - ● "All groups" (default selected)
2. **One Group:**
   - When selected: dropdown appears below
   - Dropdown lists all groups in course
   - Each item: "Group 1 (25 students)"
   - Single selection
3. **Multiple Groups:**
   - When selected: multi-select appears below
   - Can tap to open bottom sheet with checkboxes
   - Each item: "Group 1 (25 students)"
   - Can select/deselect multiple
   - Shows count: "2 groups selected"
   - "Select All" and "Clear All" buttons
4. **All Groups:**
   - When selected: no additional input
   - Shows info text: "This will be sent to all 50 students"
5. **Validation:**
   - Must select scope before publishing
   - If "One group" selected but no group chosen: show error
   - If "Multiple groups" but none selected: show error
6. **Confirmation:**
   - Before publish, show summary:
     - "Send to: Group 1, Group 2"
     - "Total: 50 students"

**Business Rules:**
- Scope is required field
- Groups must belong to current course
- Groups must be active (not deleted)
- Empty groups: show warning but allow publish
- Scope locked after publish (cannot change)

**UI Notes:**
- Radio buttons 56px touch height
- Clear visual feedback for selected option
- Multi-select bottom sheet smooth animation

---

## 📋 USER STORIES - PHASE 3: ENGAGEMENT

### Story 3.1: Post Comment on Announcement
**As an** Instructor  
**I want to** comment on my announcement  
**So that** I can provide clarifications or respond to students

**Acceptance Criteria:**
1. **Comment Input (in detail view):**
   - Section below announcement content
   - Label: "Comments (5)"
   - Input area:
     - Instructor avatar (left)
     - Text field: "Add a comment..."
     - Max 500 characters
     - Character counter (shows when >450 chars)
     - Post button (right)
2. **Posting Comment:**
   - Tap Post button
   - Validate: not empty, max 500 chars
   - Show loading on button
   - Post to API
   - Success: comment appears in list immediately
   - Input clears
   - No page reload needed
3. **Comment Display:**
   - Comment card shows:
     - Avatar + Name
     - Badge: "Instructor" (colored, small)
     - Comment text
     - Timestamp (relative: "Just now", "5 mins ago")
     - Reply button
4. **Comments List:**
   - Sorted: newest first
   - All comments visible
   - If >10 comments: "Load more" button at bottom

**Business Rules:**
- Both instructor and students can comment
- Instructor comments have special badge
- Comments visible to all students in announcement scope
- Cannot edit/delete comments after posted

**UI Notes:**
- Input field expands as typing
- Character counter turns red when approaching limit
- Instructor badge distinct color (blue)
- Avatar size consistent (40px)

---

### Story 3.2: Reply to Comments
**As an** Instructor  
**I want to** reply to specific student comments  
**So that** I can engage in focused discussions

**Acceptance Criteria:**
1. **Reply Button:**
   - Each comment has "Reply" button (bottom-right)
   - Tap Reply: reply input appears below that comment
2. **Reply Input:**
   - Same as comment input: avatar + text field + Post button
   - Placeholder: "Reply to [Name]..."
   - Max 500 characters
   - Character counter
3. **Posting Reply:**
   - Tap Post button
   - Validate and post to API
   - Reply appears nested under original comment
   - Indented 24px to show threading
4. **Reply Display:**
   - Nested under parent comment
   - Same card format as comment
   - Shows who it's replying to
   - Timestamp (relative)
5. **Threading:**
   - Max 1 level: Comment → Reply (no reply to reply)
   - Replies grouped under parent
   - Show "3 replies" count on parent
   - Tap to expand/collapse replies

**Business Rules:**
- Only 1 level of threading allowed
- Replies visible to same audience as parent comment
- Cannot reply to a reply (only to original comment)

**UI Notes:**
- Clear visual indentation for replies
- Different background shade for replies
- Collapse/expand animation smooth

---

### Story 3.3: Track Who Viewed Announcement
**As an** Instructor  
**I want to** see which students viewed my announcement  
**So that** I can ensure message delivery

**Acceptance Criteria:**
1. **Access:**
   - In detail view, button: "👁 35/50 students viewed"
   - Tap button: opens tracking modal (bottom sheet)
2. **Modal Header:**
   - Title: "View Tracking"
   - Subtitle: announcement title (truncated)
   - Close button (X)
3. **Summary Section:**
   - Card showing:
     - "35/50 students viewed (70%)"
     - Progress bar (colored green, 70% filled)
4. **Filter Bar:**
   - Group dropdown: "All Groups" or specific group
   - Status dropdown: "All" / "Viewed" / "Not Viewed"
5. **Search Bar:**
   - Icon: 🔍
   - Placeholder: "Search student name..."
   - Real-time search as typing
6. **Students List:**
   - Each row shows:
     - Avatar + Student Name
     - Group name (subtitle, gray)
     - Status icon: ✓ (green) if viewed, ✗ (red) if not
     - Timestamp (if viewed): "2 hours ago"
     - View count badge (if >1 view): "×2"
   - Scrollable list
7. **Sorting:**
   - Sort by: Name (A-Z), Group, Status, Time
8. **Empty State:**
   - If no results: "No students match your filter"

**Business Rules:**
- View counted when student opens announcement detail
- Multiple views per student tracked
- Real-time updates (or refresh button)
- Data persists even if announcement deleted

**UI Notes:**
- Bottom sheet 90% screen height
- List items 64px touch height
- Progress bar animated fill
- Status icons clear and colorful

---

### Story 3.4: Track File Downloads
**As an** Instructor  
**I want to** see who downloaded attached files  
**So that** I can track material distribution

**Acceptance Criteria:**
1. **Access:**
   - In detail view, button: "📥 Download statistics"
   - Only visible if announcement has files
   - Tap button: opens tracking modal
2. **Modal Structure (if multiple files):**
   - Tabs at top: "All files", "File1.pdf", "File2.ppt"
   - Swipe or tap to switch tabs
3. **Per-File Summary:**
   - Card showing:
     - "30/50 students downloaded File1.pdf (60%)"
     - Progress bar (colored blue, 60% filled)
4. **Filter/Search:**
   - Same as view tracking:
     - Group filter
     - Status: "Downloaded" / "Not Downloaded"
     - Search by student name
5. **Students List (per file):**
   - Each row shows:
     - Avatar + Student Name
     - Group name (subtitle)
     - Downloaded status: ✓ or ✗
     - Download timestamp (if downloaded): "Yesterday"
     - Download count badge (if >1): "×3"
   - Scrollable list
6. **All Files Tab:**
   - Shows aggregated data
   - Each row: Student + all files status
   - Columns: Name, Group, File1 (✓), File2 (✗), etc.

**Business Rules:**
- Download tracked when student clicks download button
- Multiple downloads per student per file tracked
- Track per file individually
- Preview doesn't count as download

**UI Notes:**
- Tabs clear and easy to switch
- Per-file different progress bar colors
- Same list item height as view tracking (64px)

---

## 📋 USER STORIES - PHASE 4: ENHANCEMENTS

### Story 4.1: Filter Announcements by Group
**As an** Instructor  
**I want to** filter announcements by group  
**So that** I can quickly find announcements for specific groups

**Acceptance Criteria:**
1. **Filter UI:**
   - Dropdown in list header: "All Groups" (default)
   - Lists all groups in course: "Group 1", "Group 2", etc.
2. **Filter Logic:**
   - Select group: list updates to show only announcements sent to that group
   - Includes announcements where:
     - Scope = "One group" AND selected group
     - Scope = "Multiple groups" AND selected group in list
     - Scope = "All groups"
3. **Visual Feedback:**
   - Filter active: dropdown shows selected group
   - List shows count: "5 announcements"
4. **Clear Filter:**
   - Select "All Groups": shows all announcements again
5. **Persistence:**
   - Filter state saved when navigating away
   - Returns to same filter when coming back

**Business Rules:**
- Filter applies to current course only
- Combine with sort (filter then sort)

**UI Notes:**
- Dropdown follows Material Design
- Smooth list update animation

---

### Story 4.2: Sort Announcements
**As an** Instructor  
**I want to** sort announcements by date  
**So that** I can view them in my preferred order

**Acceptance Criteria:**
1. **Sort UI:**
   - Dropdown in list header: "Newest" (default)
   - Options: "Newest", "Oldest", "Most viewed", "Most commented"
2. **Sort Logic:**
   - Newest: sort by published_at DESC
   - Oldest: sort by published_at ASC
   - Most viewed: sort by view_count DESC
   - Most commented: sort by comment_count DESC
3. **Visual Feedback:**
   - Current sort option highlighted in dropdown
4. **Persistence:**
   - Sort preference saved per user
   - Persists across sessions

**Business Rules:**
- Sort works with filter (filter then sort)
- Sort applies immediately without reload

**UI Notes:**
- Dropdown icon indicates current sort direction
- List animates when re-ordering

---

## 🔄 IMPLEMENTATION PRIORITY

### Sprint 1 (Week 1) - MVP Core
- [ ] Story 1.1: Create and Publish Announcement
- [ ] Story 1.2: View List of Announcements
- [ ] Story 1.3: View Announcement Detail

### Sprint 2 (Week 2) - Edit/Delete
- [ ] Story 1.4: Edit Announcement
- [ ] Story 1.5: Delete Announcement
- [ ] Story 2.1: Attach Files to Announcement
- [ ] Story 2.2: Select Announcement Scope

### Sprint 3 (Week 3) - Engagement
- [ ] Story 3.1: Post Comment on Announcement
- [ ] Story 3.2: Reply to Comments
- [ ] Story 3.3: Track Who Viewed Announcement

### Sprint 4 (Week 4) - Polish
- [ ] Story 3.4: Track File Downloads
- [ ] Story 4.1: Filter Announcements by Group
- [ ] Story 4.2: Sort Announcements

---

## 🗄️ DATA REQUIREMENTS

### Announcement Entity
**Fields:**
- id (unique identifier)
- course_id (belongs to course)
- instructor_id (created by instructor)
- title (string, max 200)
- content (rich text HTML)
- scope_type (enum: one_group, multiple_groups, all_groups)
- group_ids (array of group IDs, null if all_groups)
- published_at (timestamp)
- updated_at (timestamp)
- is_deleted (boolean, for soft delete)

**Relationships:**
- Belongs to: Course
- Created by: User (instructor)
- Has many: Files, Comments, Views, Downloads

### File Entity
**Fields:**
- id
- announcement_id
- file_name
- file_url (storage URL)
- file_size (bytes)
- file_type
- uploaded_at

### Comment Entity
**Fields:**
- id
- announcement_id
- user_id (instructor or student)
- parent_comment_id (null for top-level, id for reply)
- comment_text (max 500 chars)
- created_at
- is_deleted

### View Tracking Entity
**Fields:**
- id
- announcement_id
- student_id
- viewed_at (first view timestamp)
- view_count (increments on each view)

### Download Tracking Entity
**Fields:**
- id
- file_id
- student_id
- downloaded_at

---

## ✅ DEFINITION OF DONE

Each user story is DONE when:
- [ ] Functionality works as described in acceptance criteria
- [ ] UI matches UX guidelines (spacing, colors, typography, touch targets)
- [ ] Mobile layout works correctly
- [ ] Form validations working with inline errors
- [ ] Loading states shown during API calls
- [ ] Success/error messages displayed appropriately
- [ ] Empty states handled
- [ ] Error scenarios handled gracefully
- [ ] Data persists correctly in database
- [ ] Aligns with existing database schema
- [ ] Business rules enforced
- [ ] Tested with real data scenarios

---

## 🚫 OUT OF SCOPE (MVP)

Not included in MVP:
- Draft saving
- Rich text editor advanced features (just basic: bold, italic, lists)
- Notifications to students (separate feature)
- CSV export of tracking data
- Bulk operations
- Announcement templates
- Schedule publish (future date)
- Pin important announcements
- Archive announcements
