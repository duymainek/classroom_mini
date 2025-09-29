# Material 3 Form Design Guide

## 📋 Tổng quan
Hướng dẫn thiết kế form theo Material 3 design system được áp dụng cho `quiz_form.dart` và sẽ được sử dụng làm chuẩn cho tất cả các form trong ứng dụng.

## 🎨 Design Principles

### 1. **Layout Structure**
```dart
// Sử dụng CustomScrollView với SliverAppBar
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(...),
    ),
  ],
)
```

### 2. **Section Design Pattern**
```dart
Widget _buildModernSection(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // Section Header với gradient background
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Section Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: children),
        ),
      ],
    ),
  );
}
```

## 🎯 Component Standards

### 1. **Text Fields**
```dart
Widget _buildModernTextField({
  TextEditingController? controller,
  String? initialValue,
  required String label,
  String? hint,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  TextInputType? keyboardType,
  int maxLines = 1,
  IconData? prefixIcon,
}) {
  return TextFormField(
    controller: controller,
    initialValue: initialValue,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
    ),
  );
}
```

### 2. **Switch Tiles**
```dart
Widget _buildModernSwitchTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  required IconData icon,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.2),
      ),
    ),
    child: SwitchListTile(
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      )),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      )),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: colorScheme.primary),
      activeColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
```

### 3. **Date Pickers**
```dart
Widget _buildModernDateTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required DateTime? value,
  required VoidCallback onTap,
  required IconData icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.2),
      ),
    ),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      )),
      subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      )),
      trailing: Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
```

### 4. **Action Buttons**
```dart
// Primary Action Button
FilledButton(
  onPressed: onPressed,
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Save'),
)

// Secondary Action Button
OutlinedButton(
  onPressed: onPressed,
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Cancel'),
)
```

## 🎨 Color System

### **Primary Colors**
- `colorScheme.primary` - Main brand color
- `colorScheme.primaryContainer` - Light background for primary elements
- `colorScheme.onPrimary` - Text on primary background
- `colorScheme.onPrimaryContainer` - Text on primary container

### **Surface Colors**
- `colorScheme.surface` - Main background
- `colorScheme.surfaceVariant` - Secondary background
- `colorScheme.onSurface` - Text on surface
- `colorScheme.onSurfaceVariant` - Secondary text

### **State Colors**
- `colorScheme.error` - Error states
- `colorScheme.errorContainer` - Error backgrounds
- `colorScheme.secondary` - Secondary actions
- `colorScheme.outline` - Borders and dividers

## 📏 Spacing System

### **Grid System (8px)**
```dart
const EdgeInsets.all(8)    // Small spacing
const EdgeInsets.all(12)   // Medium spacing  
const EdgeInsets.all(16)   // Large spacing
const EdgeInsets.all(20)   // Section padding
const EdgeInsets.all(24)   // Section margins
```

### **Border Radius**
```dart
BorderRadius.circular(8)   // Small elements (chips, badges)
BorderRadius.circular(12)  // Form controls, buttons
BorderRadius.circular(16)  // Cards, sections
BorderRadius.circular(20)  // Large containers
```

## 🔤 Typography Scale

### **Text Styles**
```dart
// Headers
theme.textTheme.headlineSmall?.copyWith(
  fontWeight: FontWeight.bold,
  color: colorScheme.onSurface,
)

// Section Titles
theme.textTheme.titleLarge?.copyWith(
  fontWeight: FontWeight.bold,
  color: colorScheme.onSurface,
)

// Form Labels
theme.textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.w600,
)

// Body Text
theme.textTheme.bodyMedium?.copyWith(
  color: colorScheme.onSurfaceVariant,
)

// Small Text
theme.textTheme.bodySmall?.copyWith(
  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
)
```

## 🎭 Interactive States

### **Loading States**
```dart
// Button Loading
child: isLoading
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : const Text('Save'),

// Section Loading
if (isLoading)
  Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        CircularProgressIndicator(color: colorScheme.primary),
        const SizedBox(height: 16),
        Text('Loading...', style: theme.textTheme.bodyMedium),
      ],
    ),
  ),
```

### **Empty States**
```dart
Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: colorScheme.surfaceVariant.withOpacity(0.3),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: colorScheme.outline.withOpacity(0.2),
    ),
  ),
  child: Column(
    children: [
      Icon(
        Icons.inbox_outlined,
        size: 48,
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
      const SizedBox(height: 16),
      Text(
        'No items available',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Description of empty state',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),
```

## 📱 Responsive Considerations

### **Form Layout**
- Sử dụng `CustomScrollView` cho smooth scrolling
- `SliverAppBar` với `pinned: true` cho navigation
- Responsive padding với `EdgeInsets.all(16)`

### **Button Layout**
```dart
// Bottom Action Buttons
Row(
  children: [
    if (onCancel != null) ...[
      Expanded(
        child: OutlinedButton(...),
      ),
      const SizedBox(width: 16),
    ],
    Expanded(
      flex: 2, // Primary button takes more space
      child: FilledButton(...),
    ),
  ],
)
```

## 🎯 Best Practices

### **1. Consistency**
- Luôn sử dụng Material 3 color tokens
- Áp dụng 8px grid system cho spacing
- Sử dụng consistent border radius (8, 12, 16, 20)

### **2. Accessibility**
- Đảm bảo contrast ratio tối thiểu 4.5:1
- Sử dụng semantic colors cho states
- Cung cấp clear visual feedback

### **3. Performance**
- Sử dụng `const` constructors khi có thể
- Tránh rebuild không cần thiết với proper state management
- Optimize images và icons

### **4. User Experience**
- Clear visual hierarchy với proper typography
- Consistent interaction patterns
- Helpful empty states và loading states
- Intuitive navigation với proper back buttons

## 📝 Implementation Checklist

### **Khi tạo form mới:**
- [ ] Sử dụng `CustomScrollView` với `SliverAppBar`
- [ ] Chia form thành sections với `_buildModernSection`
- [ ] Áp dụng Material 3 color tokens
- [ ] Sử dụng 8px grid system cho spacing
- [ ] Implement proper loading states
- [ ] Add empty states cho dynamic content
- [ ] Test responsive behavior
- [ ] Verify accessibility compliance

### **Code Review Checklist:**
- [ ] Consistent use of Material 3 components
- [ ] Proper color token usage
- [ ] Consistent spacing và typography
- [ ] Loading states implemented
- [ ] Error handling với proper styling
- [ ] Accessibility considerations
- [ ] Performance optimizations

---

**Lưu ý:** Hướng dẫn này được tạo dựa trên implementation của `quiz_form.dart` và sẽ được cập nhật khi có thêm patterns mới. Tất cả các form trong ứng dụng nên tuân theo các nguyên tắc thiết kế này để đảm bảo tính nhất quán và trải nghiệm người dùng tốt nhất.
