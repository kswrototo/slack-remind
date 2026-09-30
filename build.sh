#!/bin/zsh
# SlackRemind.app을 만든다. 사용: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

APP=build/SlackRemind.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>kr.co.rototobebe.slackremind</string>
  <key>CFBundleName</key><string>SlackRemind</string>
  <key>CFBundleExecutable</key><string>SlackRemind</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSRemindersFullAccessUsageDescription</key><string>Slack에서 등록한 할 일을 미리알림 목록에 저장한다.</string>
</dict>
</plist>
EOF

# Apple Silicon과 Intel Mac 양쪽에서 돌도록 두 가지로 빌드해 합친다
for ARCH in arm64 x86_64; do
  swiftc -parse-as-library -swift-version 5 -target $ARCH-apple-macosx14.0 \
    -o "build/SlackRemind-$ARCH" SlackRemind.swift
done
lipo -create build/SlackRemind-arm64 build/SlackRemind-x86_64 -output "$APP/Contents/MacOS/SlackRemind"
rm build/SlackRemind-arm64 build/SlackRemind-x86_64

"$APP/Contents/MacOS/SlackRemind" --selftest
# 고정 서명이 있으면 그것으로 서명한다. 재빌드해도 미리알림 권한과 키체인 토큰이 유지된다.
if security find-identity -p codesigning | grep -q "SlackRemind Dev"; then
  codesign --force --sign "SlackRemind Dev" "$APP"
else
  codesign --force --sign - "$APP"
fi

# 배포용 묶음. 받는 사람은 압축을 풀어 응용 프로그램 폴더로 옮긴다.
mkdir -p ../output
rm -f ../output/SlackRemind.zip
ditto -c -k --keepParent "$APP" ../output/SlackRemind.zip
echo "완료: $PWD/$APP"
echo "배포용: $(cd ../output && pwd)/SlackRemind.zip"
