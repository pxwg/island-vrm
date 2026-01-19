#!/bin/bash

APP_NAME="BoringNotchMVP"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

USE_DEBUG_SERVER=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --debug)
            if [ "$2" == "true" ]; then USE_DEBUG_SERVER=true; else USE_DEBUG_SERVER=false;fi
            shift; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

echo "🧹 Cleaning up..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$RESOURCES_DIR"

echo "🚀 Compiling Swift sources..."

SWIFT_FLAGS="-O"
if [ "$USE_DEBUG_SERVER" = true ]; then
    echo "🚧 Building with DEBUG_SERVER mode enabled..."
    SWIFT_FLAGS="$SWIFT_FLAGS -D DEBUG_SERVER"
fi

# [修改] 添加 APIModels.swift 和 LocalServer.swift
swiftc \
    APIModels.swift \
    LocalServer.swift \
    NotchShape.swift \
    NotchConfig.swift \
    NotchViewModel.swift \
    NotchView.swift \
    NotchWindow.swift \
    VRMWebView.swift \
    main.swift \
    -o "$EXECUTABLE" \
    -target arm64-apple-macos14.0 \
    -sdk $(xcrun --show-sdk-path) \
    $SWIFT_FLAGS

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed."
    exit 1
fi

echo "📦 Building Web Frontend..."
# 检查 web 目录是否存在
if [ -d "web" ]; then
    cd web
    npm run build
    cd ..
else
    echo "⚠️ 'web' directory not found, skipping frontend build."
fi

echo "📂 Copying WebResources..."
if [ -d "WebResources" ]; then
    cp -r "WebResources" "$RESOURCES_DIR/"
else
    echo "⚠️ Warning: 'WebResources' folder not found! WebView will be empty."
fi

echo "📝 Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "✍️  Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build successful!"
echo "👉 Run with: open $APP_BUNDLE"
