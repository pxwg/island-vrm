swiftc \
  NotchShape.swift \
  NotchConfig.swift \
  NotchViewModel.swift \
  NotchView.swift \
  NotchWindow.swift \
  main.swift \
  -o BoringNotchMVP \
  -target arm64-apple-macos14.0 \
  -sdk $(xcrun --show-sdk-path)
