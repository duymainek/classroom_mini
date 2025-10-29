# FORUM MANAGEMENT - UI/UX DESIGN REQUIREMENTS (Threads-Inspired)

## 🎯 DESIGN PHILOSOPHY

**Inspired by:** Threads by Meta - Clean, conversational, engagement-focused design

**Core Principles:**
- Conversation-first designipho
- Minimal friction to post
- Clear visual hierarchy for threading
- Fast, fluid interactions
- Mobile-native experience

---

## 📱 SCREEN STRUCTURE

### 1. FORUM FEED (Main Screen)

**Layout Pattern: Threads-style Feed**

```
┌─────────────────────────────────┐
│ ← Forum          🔍  ┋           │ ← Header (56px)
├─────────────────────────────────┤
│                                 │
│  ╭───────────────────────────╮ │ ← Topic Card
│  │ 👤 Nguyen Van A · 2h       │ │   Compact, clean
│  │                            │ │
│  │ How to implement Redux?    │ │   Title (bold, 16px)
│  │                            │ │
│  │ I'm having trouble with... │ │   Preview (14px, 2 lines)
│  │                            │ │
│  │ 📎 code.png                │ │   Attachment indicator
│  │                            │ │
│  │ 💬 12  ↗ 3  👁 45          │ │   Stats (subtle, 12px)
│  ╰───────────────────────────╯ │
│         8px gap                 │
│  ╭───────────────────────────╮ │
│  │ 👤 Tran Thi B · 5h        │ │
│  │ Assignment 1 doubt...      │ │
│  │ ...                        │ │
│  ╰───────────────────────────╯ │
│                                 │
│                                 │
└─────────────────────────────────┘
        ┃
        ┃ 64px padding from bottom
        ▼
   ╭─────────╮
   │    ✏️    │ ← FAB (Floating Action Button)
   ╰─────────╯   56x56px, primary color
                 Create new topic
```

**Key Elements:**

**Header Bar (56px height):**
- [ ] Back button (if navigated from course)
- [ ] Title: "Forum" (bold, 18px)
- [ ] Search icon (tap → open search)
- [ ] 3-dot menu (filter/sort options)

**Topic Cards (each card):**
- [ ] Avatar + Name + Timestamp (one line)
  - Avatar: 32px circle
  - Name: 14px, semibold
  - Timestamp: 12px, grey, relative ("2h", "1d")
  - Spacing: 4px between elements
- [ ] Topic Title (bold, 16px, max 2 lines)
- [ ] Content Preview (14px, grey, max 2 lines, ellipsis)
- [ ] Attachment indicator (if has files)
  - Icon 📎 + filename or count
  - Small, subtle
- [ ] Stats Row:
  - 💬 Reply count
  - ↗ Share/bookmark (optional)
  - 👁 View count
  - Icons 16px, text 12px, grey
  - Spacing: 16px between stats
- [ ] Card styling:
  - No border or subtle border (1px, light grey)
  - Background: white or slight off-white
  - Padding: 12px
  - Border radius: 12px
  - Margin: 8px horizontal, 4px vertical
  - Tap: slight scale down (0.98) + navigate to detail

**Empty State:**
- [ ] Centered illustration
- [ ] "No topics yet"
- [ ] "Start a discussion!" button

**FAB (Floating Action Button):**
- [ ] Position: bottom-right, 16px from edges
- [ ] Size: 56x56px
- [ ] Icon: ✏️ or ➕
- [ ] Color: primary brand color
- [ ] Shadow: elevation 6dp
- [ ] Tap: smooth scale animation + open create sheet

---

### 2. CREATE TOPIC (Bottom Sheet) - Threads Composer Style

**Design Pattern: Full-screen bottom sheet với smooth slide-up animation**

```
┌─────────────────────────────────┐
│ ✕                    Post       │ ← Header (sticky)
├─────────────────────────────────┤
│                                 │
│ 👤 Instructor Name              │ ← User identity
│    ▼ Public to all students     │   Context info
│                                 │
│ ─────────────────────────────── │ ← Thin divider
│                                 │
│ 📝 What's on your mind?         │ ← Title input
│                                 │   Placeholder, auto-focus
│ ═════════════════════════════   │ ← Bold underline (active)
│                                 │
│ [Content text area]             │ ← Multiline content
│ Share details, ask questions... │   Placeholder
│                                 │   Min-height: 120px
│                                 │   Auto-expand as typing
│                                 │
│                                 │
│ 📎 📷 🔗                         │ ← Action buttons
│                                 │   Attach, Photo, Link
│                                 │
│ ╭──────────────────╮            │ ← Attachment preview
│ │ 📄 assignment.pdf │            │   (if attached)
│ │ 2.5 MB        ✕  │            │
│ ╰──────────────────╯            │
│                                 │
└─────────────────────────────────┘
```

**Key Elements:**

**Header (56px, sticky at top):**
- [ ] Close button (✕) - top-left
  - Tap: confirm exit if has content
  - Dialog: "Discard draft?"
- [ ] "Post" button - top-right
  - Initially disabled (grey)
  - Enabled when title filled (primary color)
  - Loading spinner when posting

**User Context (below header):**
- [ ] Avatar (40px) + Name (14px, bold)
- [ ] Visibility info: "Public to all students in [Course Name]"
  - 12px, grey
  - Tap: show info dialog about who can see

**Title Input:**
- [ ] Large, bold input field
- [ ] Placeholder: "What's on your mind?" or "Topic title..."
- [ ] Font: 18px, bold
- [ ] No border, underline only (Threads style)
- [ ] Max 200 characters
- [ ] Character counter appears at 180 chars
- [ ] Auto-focus on open

**Content Input:**
- [ ] Multiline text area
- [ ] Placeholder: "Share details, ask questions, start a discussion..."
- [ ] Font: 16px, regular
- [ ] Min height: 120px
- [ ] Auto-expand as typing (up to 60% screen)
- [ ] No visible border (clean look)
- [ ] Max 5000 characters
- [ ] Character counter at bottom-right (when > 4500)

**Action Buttons Row:**
- [ ] 3 icon buttons: 📎 Attach, 📷 Photo, 🔗 Link
- [ ] Each 44x44px touch target
- [ ] Subtle grey background
- [ ] Spacing: 8px between buttons
- [ ] Tap animations: scale down

**Attachment Preview (if added):**
- [ ] Small card showing file
- [ ] File icon + name + size
- [ ] Remove button (X) - top-right
- [ ] Max 3 files visible, scroll horizontal if more
- [ ] Image attachments: show thumbnail

**Keyboard Behavior:**
- [ ] Sheet adjusts height when keyboard appears
- [ ] Content scrollable above keyboard
- [ ] "Post" button always visible

---

### 3. TOPIC DETAIL (Threaded View) - Threads Conversation Style

**Design Pattern: Vertical thread with clear visual hierarchy**

```
┌─────────────────────────────────┐
│ ← Topic          •••             │ ← Header
├─────────────────────────────────┤
│                                 │
│ ╭─────────────────────────────╮ │ ← Original Post (OP)
│ │ 👤 Nguyen Van A · 2h    •••  │ │   Larger, prominent
│ │                              │ │
│ │ How to implement Redux?      │ │   Title (bold, 18px)
│ │                              │ │
│ │ I'm building a React app and │ │   Full content
│ │ struggling with state manage │ │   (readable, 16px)
│ │ ment. Can anyone explain... │ │
│ │                              │ │
│ │ ╭────────────────────╮       │ │   Image preview
│ │ │  [Image preview]   │       │ │   (if attached)
│ │ ╰────────────────────╯       │ │
│ │                              │ │
│ │ 📎 code.png                  │ │   Other attachments
│ │                              │ │
│ │ 💬 Reply  ↗ Share  👁 45     │ │   Actions
│ ╰─────────────────────────────╯ │
│                                 │
│ ─────  12 replies  ───────────  │ ← Divider with count
│                                 │
│ ┃ 👤 Tran Thi B · 1h            │ ← Reply (connected)
│ ┃ You should use Redux Toolkit  │   Thread line (left)
│ ┃ ...                           │   Slightly indented
│ ┃ 💬 2  ♡ 5                     │   Reply actions
│ ┃                               │
│ ┃ ┃ 👤 Instructor · 30m         │ ← Nested reply
│ ┃ ┃ Great suggestion!           │   Double indent
│ ┃ ┃ ♡ 2                         │   Thinner thread line
│ ┃ ┃                             │
│ ┃ 👤 Le Van C · 45m             │ ← Another reply
│ ┃ Check out this tutorial...   │   (same level as B)
│ ┃ 🔗 link                       │
│ ┃ ♡ 3                           │
│                                 │
│ ─────────────────────────────── │
│                                 │
│ 💬 Write a reply...      [Send] │ ← Reply input (sticky)
└─────────────────────────────────┘
```

**Key Elements:**

**Original Post (OP) Card:**
- [ ] Larger card, more padding (16px)
- [ ] Avatar (40px) + Name + Timestamp
- [ ] 3-dot menu (edit/delete if own post)
- [ ] Title: 18px, bold, full display (no truncation)
- [ ] Content: 16px, full display, selectable text
- [ ] Image attachments: 
  - Full width preview
  - Tap: open fullscreen gallery
  - Multiple images: horizontal scroll with dots indicator
- [ ] File attachments:
  - Card style: icon + name + size
  - Tap: download or preview
- [ ] Actions row:
  - 💬 Reply button (primary action)
  - ↗ Share (optional)
  - 👁 View count
  - ••• More (bookmark, report)

**Thread Visual System:**
- [ ] Vertical line connecting replies (Threads-style)
  - 2px width
  - Light grey color
  - Connects from avatar to avatar
  - 16px offset from left
- [ ] Replies indented 40px from left
- [ ] Nested replies indented additional 40px
- [ ] Max 2 levels of nesting (reply → reply to reply)

**Reply Cards:**
- [ ] Smaller padding (12px)
- [ ] Avatar (32px) + Name + Timestamp (one line)
- [ ] Content: 14px, max 500 characters
- [ ] Minimal actions:
  - 💬 Reply count (tap to expand nested)
  - ♡ Like count (tap to like/unlike)
  - Timestamp doubles as "Reply" tap target
- [ ] Special badges:
  - "Instructor" badge if instructor reply (blue pill)
  - "OP" badge if original poster replies (grey pill)

**Divider Between OP and Replies:**
- [ ] Thin line with centered text
- [ ] Text: "12 replies" (grey, 12px)
- [ ] 24px top/bottom margin

**Reply Input (Sticky Bottom):**
- [ ] Avatar (28px) + Input field
- [ ] Placeholder: "Write a reply..."
- [ ] Max 500 characters
- [ ] Send button (always visible, enabled when text entered)
- [ ] Tap input: expand to bottom sheet for longer replies
- [ ] Keyboard-aware: pushes up with keyboard

**Collapse/Expand Threads:**
- [ ] Long threads (>5 replies): show "Show 8 more replies" button
- [ ] Tap: expand inline
- [ ] Tap username on thread line: collapse that thread

---

### 4. NESTED REPLY (Bottom Sheet)

**When replying to a specific comment (not OP):**

```
┌─────────────────────────────────┐
│ ✕              Reply             │
├─────────────────────────────────┤
│                                 │
│ Replying to Tran Thi B          │ ← Context (bold)
│                                 │
│ ╭─────────────────────────────╮ │ ← Quoted parent
│ │ "You should use Redux..."   │ │   (grey background)
│ ╰─────────────────────────────╯ │
│                                 │
│ 💬 Write your reply...          │ ← Input (auto-focus)
│                                 │
│ [Text area]                     │
│                                 │
│ 0/500                     [Post]│ ← Counter + Action
└─────────────────────────────────┘
```

**Key Elements:**
- [ ] Header: "Reply" with close button
- [ ] Context line: "Replying to [Name]"
- [ ] Quoted parent comment (first 100 chars, grey card)
- [ ] Text input (auto-focus)
- [ ] Character limit: 500
- [ ] Post button (top-right, enabled when text entered)

---

### 5. SEARCH & FILTER

**Search Bar (activated from header):**
```
┌─────────────────────────────────┐
│ ← 🔍 Search topics...           │ ← Full-width search
├─────────────────────────────────┤
│                                 │
│ Recent searches:                │ ← Suggestions
│ • Redux implementation          │
│ • Assignment 1                  │
│ • Group project                 │
│                                 │
│ ─────────────────────────────── │
│                                 │
│ [Search results appear here]    │ ← Results
│                                 │
└─────────────────────────────────┘
```

**Filter Bottom Sheet:**
- [ ] Sort by:
  - Latest (default)
  - Most replies
  - Most viewed
- [ ] Filter by:
  - My topics
  - Topics I replied to
  - Unanswered topics
- [ ] Date range (optional)

---

## 🎨 VISUAL DESIGN SYSTEM

### Colors (Threads-inspired, professional)
```dart
// Primary actions
primaryColor: #000000 (black for text, buttons)
primaryAccent: #0095F6 (blue for links, actions)

// Backgrounds
backgroundColor: #FFFFFF (pure white)
cardBackground: #FAFAFA (slight off-white)
threadLineColor: #DBDBDB (light grey for connection lines)

// Text hierarchy
textPrimary: #000000 (titles, names)
textSecondary: #737373 (timestamps, metadata)
textTertiary: #A8A8A8 (placeholders)

// Interactive states
likeColor: #ED4956 (red for likes)
replyColor: #0095F6 (blue for reply actions)
highlightColor: #EFEFEF (tap feedback)

// Badges
instructorBadge: #0095F6 (blue pill)
opBadge: #DBDBDB (grey pill)
```

### Typography
```dart
// Threads uses SF Pro (iOS) / Roboto (Android)
postTitle: 18px, bold, letterSpacing: -0.3
postContent: 16px, regular, lineHeight: 1.5
replyContent: 14px, regular, lineHeight: 1.4
metadata: 12px, regular (timestamps, counts)
userName: 14px, semibold
badges: 11px, semibold, uppercase
```

### Spacing (8px grid)
```dart
screenPadding: 16px (horizontal)
cardPadding: 12-16px (based on hierarchy)
elementSpacing: 8px (between elements)
sectionSpacing: 24px (between sections)
avatarSize: 40px (OP), 32px (reply), 28px (input)
threadLineOffset: 16px (from left edge)
indentSize: 40px (per nesting level)
```

### Touch Targets
```dart
minTouchTarget: 44x44px (all tappable areas)
fabSize: 56x56px
iconButtons: 44x44px (with padding)
listItems: min 64px height
replyCards: min 56px height
```

### Animations (Threads-style smooth)
```dart
// All animations: 300ms ease-out curve
fadeIn: opacity 0 → 1 (200ms)
slideUp: translateY 100% → 0 (300ms)
scaleDown: scale 1 → 0.98 (100ms, on tap)
expandCollapse: height animation (250ms)
shimmerLoading: skeleton screens (1000ms loop)
```

---

## 📱 INTERACTION PATTERNS

### Tap Behaviors (Threads-style)
- [ ] **Tap Topic Card:** Navigate to detail with slide animation
- [ ] **Tap Avatar:** Show user profile (optional in MVP)
- [ ] **Tap Images:** Open fullscreen gallery with swipe
- [ ] **Tap Files:** Download with progress indicator
- [ ] **Tap Reply Button:** 
  - On OP: focus on bottom input
  - On reply: open reply sheet with context
- [ ] **Long-press Post:** Show context menu (copy, report, etc.)
- [ ] **Pull to refresh:** Refresh feed with loading indicator
- [ ] **Scroll:** Infinite scroll, load more when near bottom

### Gestures
- [ ] **Swipe back:** Navigate back (iOS-style)
- [ ] **Swipe on image:** Navigate through image gallery
- [ ] **Pinch on image:** Zoom in/out

### Loading States
- [ ] **Initial load:** Skeleton screens (shimmering cards)
- [ ] **Load more:** Spinner at bottom of list
- [ ] **Post submit:** Button loading spinner
- [ ] **Image upload:** Progress bar on attachment card

### Empty States
- [ ] **No topics:** Illustration + "Start the conversation" CTA
- [ ] **No search results:** "No topics found" + suggestion
- [ ] **No replies yet:** "Be the first to reply"

---

## 🎯 KEY UX PRINCIPLES (Threads-inspired)

### 1. **Minimal Friction**
- Auto-focus inputs when sheets open
- Quick actions (reply, like) without navigation
- FAB always accessible for posting

### 2. **Conversational Flow**
- Thread lines clearly show conversation structure
- Nested replies easy to follow
- Context always visible when replying

### 3. **Fast Feedback**
- Immediate UI updates (optimistic rendering)
- Smooth animations (300ms or less)
- Clear loading states

### 4. **Clean Hierarchy**
- OP always prominent
- Replies visually subordinate
- Instructor replies highlighted with badge

### 5. **Mobile-Native**
- Bottom sheets for input (reachable with thumb)
- Large touch targets (44px+)
- Swipe gestures supported
- Keyboard-aware layouts

---

## ✅ IMPLEMENTATION CHECKLIST

### Feed Screen
- [ ] Topic cards với avatar, title, preview, stats
- [ ] Thread line visual system
- [ ] FAB for create topic
- [ ] Pull to refresh
- [ ] Infinite scroll pagination
- [ ] Skeleton loading states
- [ ] Empty state design

### Create Topic
- [ ] Bottom sheet composer
- [ ] Auto-focus title input
- [ ] Auto-expanding content area
- [ ] File attachment picker
- [ ] Image preview
- [ ] Character counters
- [ ] Post button enabled state
- [ ] Discard confirmation

### Topic Detail
- [ ] OP card (prominent design)
- [ ] Thread visual system (vertical lines)
- [ ] Nested replies (max 2 levels)
- [ ] Reply input (sticky bottom)
- [ ] Collapse/expand long threads
- [ ] Image gallery view
- [ ] File download handling

### Reply Flow
- [ ] Quick reply (bottom input)
- [ ] Nested reply (bottom sheet with context)
- [ ] Character limit (500)
- [ ] Instructor badge on replies
- [ ] Like functionality

### Search & Filter
- [ ] Search bar with suggestions
- [ ] Real-time search results
- [ ] Filter bottom sheet
- [ ] Sort options
- [ ] Empty search results state

---

Đây là UI/UX requirements inspired by Threads app, adapted cho education context. Bạn muốn tôi detail thêm phần nào hoặc tạo user stories cho Forum không?