#!/bin/bash
cd "$(dirname "$0")"

echo "Building Worktree Manager..."
swift build -c release

if [ $? -eq 0 ]; then
    cp -f .build/release/WorktreeManager "Worktree Manager.app/Contents/MacOS/WorktreeManager"
    echo "Launching..."
    open "Worktree Manager.app"
else
    echo "Build failed!"
    read -p "Press Enter to close..."
fi
