# File Deletion Rules

## Rule (CRITICAL)

**Skip if already deleted**: If the target file does not exist in the working tree, do nothing. This rule applies only to files that currently exist.

**NEVER** use `rm` or `unlink` commands directly.

**ALWAYS** use git stash before deleting files to preserve them.

**Before performing destructive file operations, confirm the target files with the user if the scope is large (>5 files).**

**Apply without confirmation for small scope**: When file deletion involves 5 or fewer files, follow this rule without asking the user for confirmation. Execute the deletion process defined below.

## Prohibited Commands

The following commands are **strictly prohibited**:

- `rm` (any variant)
- `unlink`
- Any direct file deletion without git stash

## Deletion Process

### For Modified Files (Tracked & Modified)

1. Save changes to git stash:

   ```bash
   git stash push -m "[Deletion] <reason>" -- <files>
   ```

2. Remove file from git:

   ```bash
   git rm <files>
   ```

### For Unmodified Files (Tracked & Unmodified)

Stash is not required for unmodified tracked files because their content is already preserved in the commit history and can be recovered with `git checkout <commit> -- <file>`.

1. Remove file from git:

   ```bash
   git rm <files>
   ```

### For New Files (Untracked)

1. Stage the file:

   ```bash
   git add <files>
   ```

2. Save to stash (file is automatically removed from working tree):

   ```bash
   git stash push -m "[Deletion] <reason>" -- <files>
   ```

## Stash Message Template

Use this format for stash messages:

```text
[Deletion] <reason>
Files: <file1>, <file2>, ...
```

### Examples

```bash
# Single file
git stash push -m "[Deletion] Remove deprecated API endpoints
Files: api/old-endpoint.js" -- api/old-endpoint.js

# Multiple files
git stash push -m "[Deletion] Clean up unused test fixtures
Files: test/fixtures/old.js, test/fixtures/deprecated.js" -- test/fixtures/old.js test/fixtures/deprecated.js

# Directory
git stash push -m "[Deletion] Remove legacy components
Files: src/components/legacy/" -- src/components/legacy/
```

## Complete Examples

### Deleting Modified File

```bash
# Step 1: Save to stash
git stash push -m "[Deletion] Remove unused utility function
Files: utils/old-helper.js" -- utils/old-helper.js

# Step 2: Remove from git
git rm utils/old-helper.js
```

### Deleting Untracked File

```bash
# Step 1: Stage file
git add temp-file.js

# Step 2: Save to stash (removes from working tree)
git stash push -m "[Deletion] Remove temporary file
Files: temp-file.js" -- temp-file.js
```

### Deleting Multiple Files

```bash
# Save all files to stash
git stash push -m "[Deletion] Clean up deprecated modules
Files: module1.js, module2.js, module3.js" -- module1.js module2.js module3.js

# Remove from git
git rm module1.js module2.js module3.js
```

## Notes

- Files saved to git stash can be recovered later if needed
- Use descriptive reasons in stash messages for future reference
- The stash preserves file contents even after deletion
- List all files in the stash message for clarity
