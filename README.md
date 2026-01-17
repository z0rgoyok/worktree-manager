# Worktree Manager

A native macOS app for managing git worktrees with a simple, intuitive interface.

## Features

- **Repository Management**: Add and track multiple git repositories
- **Worktree Operations**: Create, list, lock/unlock, and remove worktrees
- **Quick Open**: Open worktrees in your favorite editor (VS Code, Cursor, IntelliJ IDEA, etc.)
- **Finder/Terminal Integration**: Quick access to worktree locations
- **Branch Management**: Create worktrees from existing branches or create new ones

## Requirements

- macOS 14.0 (Sonoma) or later
- Git installed and available in PATH
- Xcode 15+ (for building)

## Building

```bash
cd ~/dev/tools/worktree-manager
swift build -c release
```

The binary will be at `.build/release/WorktreeManager`.

## Running

```bash
# Run directly
swift run

# Or after building
.build/release/WorktreeManager
```

## Creating an App Bundle

To create a proper macOS app bundle:

```bash
# Build release
swift build -c release

# Create app structure
mkdir -p WorktreeManager.app/Contents/MacOS
mkdir -p WorktreeManager.app/Contents/Resources

# Copy binary
cp .build/release/WorktreeManager WorktreeManager.app/Contents/MacOS/

# Create Info.plist
cat > WorktreeManager.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WorktreeManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.worktree-manager</string>
    <key>CFBundleName</key>
    <string>Worktree Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
```

Then move `WorktreeManager.app` to `/Applications` or `~/Applications`.

## Usage

1. **Add a repository**: Click the `+` button in the sidebar and select a git repository folder
2. **Create a worktree**: Select a repo, click "New Worktree", choose branch options
3. **Open in editor**: Click "Open" on any worktree card and select your editor
4. **Remove a worktree**: Use the `...` menu on a worktree card

## Configuration

Open Settings (`Cmd+,`) to configure:
- **Worktrees Location**: Where new worktrees are created (default: `~/worktrees`)
- **Default Editor**: Skip the editor picker by setting a default

## Architecture

The app follows Clean Architecture principles:

```
Sources/
├── App/                    # App entry point
├── Domain/Entities/        # Core business objects
├── Application/UseCases/   # Business logic and state
├── Infrastructure/Git/     # Git CLI wrapper, storage
└── Presentation/Views/     # SwiftUI views
```
