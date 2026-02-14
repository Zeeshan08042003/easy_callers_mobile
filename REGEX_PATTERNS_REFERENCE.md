# Regex Patterns Reference - Excel Column Matching

## 📚 Understanding the Regex Patterns

This document explains the regex patterns used in the Excel upload service for column matching.

---

## 🔍 Pattern Breakdown

### Phone Number Pattern
```regex
^(phone|mobile|cell|tel|telephone|mob|contact|whatsapp|ph|number|no)[\s_-]?(number|no|num)?\.?$
```

#### Explanation:
- `^` - Start of string
- `(phone|mobile|cell|...)` - Match any of these base words
- `[\s_-]?` - Optional space, underscore, or dash
- `(number|no|num)?` - Optional suffix
- `\.?` - Optional period at the end
- `$` - End of string

#### Matches:
- ✅ `phone`
- ✅ `mobile`
- ✅ `contact no`
- ✅ `contact_no`
- ✅ `contact-no`
- ✅ `phone number`
- ✅ `mobile no.`
- ✅ `ph no`
- ✅ `whatsapp no.`
- ✅ `number`
- ✅ `no`

---

### Name Pattern
```regex
^(name|full[\s_-]?name|client[\s_-]?name|customer[\s_-]?name|...)$
```

#### Explanation:
- `^` - Start of string
- `(name|full[\s_-]?name|...)` - Match "name" or compound words
- `[\s_-]?` - Optional separator between words
- `$` - End of string

#### Matches:
- ✅ `name`
- ✅ `full name`
- ✅ `full_name`
- ✅ `full-name`
- ✅ `client name`
- ✅ `customer name`
- ✅ `lead name`
- ✅ `contact name`

---

### First Name Pattern
```regex
^(first[\s_-]?name|f[\s_-]?name|fname)$
```

#### Explanation:
- Matches "first name" with optional separators
- Also matches abbreviations like "f name"

#### Matches:
- ✅ `first name`
- ✅ `first_name`
- ✅ `first-name`
- ✅ `firstname`
- ✅ `f name`
- ✅ `fname`

---

### Last Name Pattern
```regex
^(last[\s_-]?name|l[\s_-]?name|lname|surname|sur[\s_-]?name)$
```

#### Matches:
- ✅ `last name`
- ✅ `last_name`
- ✅ `lastname`
- ✅ `surname`
- ✅ `lname`

---

### Email Pattern
```regex
^(email|e[\s_-]?mail|mail)[\s_-]?(address|id)?$
```

#### Matches:
- ✅ `email`
- ✅ `e-mail`
- ✅ `e mail`
- ✅ `mail`
- ✅ `email address`
- ✅ `email id`

---

### Location Pattern
```regex
^(location|city|area|address|region|locality|place|town|district|state|pincode|pin[\s_-]?code|zip|postal)$
```

#### Matches:
- ✅ `location`
- ✅ `city`
- ✅ `area`
- ✅ `address`
- ✅ `pincode`
- ✅ `pin code`
- ✅ `zip`
- ✅ `postal`

---

### Project Pattern
```regex
^(project|property|scheme|flat|plot|site|tower)[\s_-]?(name)?$
```

#### Matches:
- ✅ `project`
- ✅ `project name`
- ✅ `property`
- ✅ `property name`
- ✅ `scheme`
- ✅ `flat`
- ✅ `plot`
- ✅ `tower`

---

### Budget Pattern
```regex
^(budget|amount|price|investment|range|cost|value)[\s_-]?(range)?$
```

#### Matches:
- ✅ `budget`
- ✅ `amount`
- ✅ `price`
- ✅ `price range`
- ✅ `investment`
- ✅ `cost`
- ✅ `value`

---

### Source Pattern
```regex
^(source|lead[\s_-]?source|channel|platform|origin|via|campaign|medium|portal)$
```

#### Matches:
- ✅ `source`
- ✅ `lead source`
- ✅ `lead_source`
- ✅ `channel`
- ✅ `platform`
- ✅ `campaign`

---

### Notes Pattern
```regex
^(notes?|remarks?|comments?|description|observation|feedback|status|requirement)$
```

#### Explanation:
- `notes?` - Matches "note" or "notes" (? makes 's' optional)
- `remarks?` - Matches "remark" or "remarks"
- `comments?` - Matches "comment" or "comments"

#### Matches:
- ✅ `note`
- ✅ `notes`
- ✅ `remark`
- ✅ `remarks`
- ✅ `comment`
- ✅ `comments`
- ✅ `description`
- ✅ `feedback`

---

## 🎯 Special Characters Explained

| Character | Meaning | Example |
|-----------|---------|---------|
| `^` | Start of string | `^name` matches "name" at start |
| `$` | End of string | `name$` matches "name" at end |
| `\|` | OR operator | `phone\|mobile` matches either |
| `?` | Optional (0 or 1) | `s?` matches "" or "s" |
| `[\s_-]` | Character class | Matches space, underscore, or dash |
| `\.` | Escaped period | Matches literal "." |
| `()` | Grouping | Groups alternatives together |

---

## 🧪 Testing Patterns

You can test these patterns in Dart:

```dart
bool _matchesRegex(String header, String pattern) {
  final regex = RegExp(pattern, caseSensitive: false);
  return regex.hasMatch(header);
}

// Test examples
print(_matchesRegex('contact no', r'^(phone|mobile|contact)[\s_-]?(number|no)?$')); 
// Output: true

print(_matchesRegex('Contact No.', r'^(phone|mobile|contact)[\s_-]?(number|no)?\.?$')); 
// Output: true

print(_matchesRegex('first_name', r'^(first[\s_-]?name|fname)$')); 
// Output: true
```

---

## 🔧 Adding New Patterns

To add support for new column variations:

1. **Identify the base words** you want to match
2. **Add optional separators** `[\s_-]?` between words
3. **Add optional suffixes** if needed
4. **Test with real examples**

### Example: Adding "Customer ID" support

```dart
// Pattern for ID columns
else if (_matchesRegex(h, r'^(id|customer[\s_-]?id|lead[\s_-]?id|client[\s_-]?id)$')) {
  map['customer_id'] = i;
}
```

This would match:
- `id`
- `customer id`
- `customer_id`
- `lead id`
- `client id`

---

## 📝 Best Practices

1. **Case-insensitive**: Always use `caseSensitive: false`
2. **Anchor patterns**: Use `^` and `$` to match full string
3. **Optional separators**: Use `[\s_-]?` for flexibility
4. **Test thoroughly**: Test with real-world Excel files
5. **Priority matters**: Check specific patterns before general ones

### Example Priority:
```dart
// Check "first name" BEFORE "name"
if (_matchesRegex(h, r'^(first[\s_-]?name)$')) {
  map['first_name'] = i;
}
// Then check general "name"
else if (_matchesRegex(h, r'^(name)$')) {
  map['name'] = i;
}
```

---

## 🎓 Learning Resources

- [Regex101](https://regex101.com/) - Test regex patterns online
- [RegexOne](https://regexone.com/) - Interactive regex tutorial
- [Dart RegExp Docs](https://api.dart.dev/stable/dart-core/RegExp-class.html) - Official documentation

---

**This regex-based approach makes the Excel upload feature robust and production-ready!**
