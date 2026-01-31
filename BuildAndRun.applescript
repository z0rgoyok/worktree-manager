-- Fast Build & Run launcher for WorktreeManager
-- Default behavior: build Debug incrementally and only when inputs changed.

on sh(cmd)
    return do shell script cmd
end sh

set projectPath to (POSIX path of (path to me as text)) & "../"
-- Normalize path (remove trailing slash inconsistencies)
set projectPath to sh("cd " & quoted form of projectPath & " && pwd")
set projectPathQuoted to quoted form of projectPath

set appPath to projectPath & "/Worktree Manager.app"
set contentsPath to appPath & "/Contents"
set macosPath to contentsPath & "/MacOS"
set resourcesPath to contentsPath & "/Resources"

try
    -- Create app bundle structure if it doesn't exist
    sh("mkdir -p " & quoted form of macosPath)
    sh("mkdir -p " & quoted form of resourcesPath)

    -- Create Info.plist if it doesn't exist
    set infoPlistPath to contentsPath & "/Info.plist"
    try
        sh("test -f " & quoted form of infoPlistPath)
    on error
        set plistContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\
<plist version=\"1.0\">\
<dict>\
    <key>CFBundleExecutable</key>\
    <string>WorktreeManager</string>\
    <key>CFBundleIconFile</key>\
    <string>AppIcon</string>\
    <key>CFBundleIdentifier</key>\
    <string>com.local.worktree-manager</string>\
    <key>CFBundleName</key>\
    <string>Worktree Manager</string>\
    <key>CFBundlePackageType</key>\
    <string>APPL</string>\
    <key>CFBundleShortVersionString</key>\
    <string>1.0</string>\
    <key>CFBundleVersion</key>\
    <string>1</string>\
    <key>LSMinimumSystemVersion</key>\
    <string>13.0</string>\
    <key>NSHighResolutionCapable</key>\
    <true/>\
</dict>\
</plist>"
        sh("echo " & quoted form of plistContent & " > " & quoted form of infoPlistPath)
    end try

    -- Copy icon if exists and not already in Resources
    set iconSource to projectPath & "/AppIcon.icns"
    set iconDest to resourcesPath & "/AppIcon.icns"
    try
        sh("test -f " & quoted form of iconSource & " && test ! -f " & quoted form of iconDest & " && cp " & quoted form of iconSource & " " & quoted form of iconDest)
    end try

    -- Build configuration (debug by default)
    set buildConfiguration to sh("cd " & projectPathQuoted & " && echo ${WORKTREE_MANAGER_BUILD_CONFIG:-debug}")
    if (buildConfiguration is not "debug") and (buildConfiguration is not "release") then
        set buildConfiguration to "debug"
    end if

    set forceRebuild to sh("cd " & projectPathQuoted & " && echo ${WORKTREE_MANAGER_FORCE_REBUILD:-0}")

    set builtBinaryPath to projectPath & "/.build/" & buildConfiguration & "/WorktreeManager"
    set appBinaryPath to macosPath & "/WorktreeManager"

    set buildNeeded to false
    if forceRebuild is "1" then
        set buildNeeded to true
    else
        try
            sh("test -x " & quoted form of builtBinaryPath)
        on error
            set buildNeeded to true
        end try

        if buildNeeded is false then
            set needsBuildResult to sh("cd " & projectPathQuoted & " && " & ¬
                "binary=.build/" & buildConfiguration & "/WorktreeManager; " & ¬
                "binary_mtime=$(stat -f %m \"$binary\" 2>/dev/null || echo 0); " & ¬
                "inputs_mtime=$( (find Sources -type f -print0 2>/dev/null; printf '%s\\0' Package.swift) | xargs -0 stat -f %m 2>/dev/null | sort -nr | head -1 || true ); " & ¬
                "inputs_mtime=${inputs_mtime:-0}; " & ¬
                "if [ \"$inputs_mtime\" -gt \"$binary_mtime\" ]; then echo 1; else echo 0; fi")

            if needsBuildResult is "1" then set buildNeeded to true
        end if
    end if

    if buildNeeded then
        -- Debug builds are significantly faster than release and are the best default for local iteration.
        set buildCmd to "swift build -c " & buildConfiguration
        sh("cd " & projectPathQuoted & " && " & buildCmd & " 2>&1")
    end if

    -- Copy binary into the app bundle if needed
    set needsCopyResult to sh("cd " & projectPathQuoted & " && " & ¬
        "src=.build/" & buildConfiguration & "/WorktreeManager; " & ¬
        "dst=\"" & appBinaryPath & "\"; " & ¬
        "if [ ! -f \"$dst\" ]; then echo 1; " & ¬
        "elif [ \"$src\" -nt \"$dst\" ]; then echo 1; " & ¬
        "else echo 0; fi")

    if needsCopyResult is "1" then
        sh("cp -f " & quoted form of builtBinaryPath & " " & quoted form of appBinaryPath)
        -- Remove quarantine attributes so macOS doesn't block the app
        sh("xattr -cr " & quoted form of appPath)
    end if

    -- Launch the app
    sh("open " & quoted form of appPath)

on error errMsg
    display alert "Build Failed" message errMsg as critical
end try
