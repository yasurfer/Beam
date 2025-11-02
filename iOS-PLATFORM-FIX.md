# iOS Platform Fix - ContactInfoView

## Issue
When compiling for iPhone 14, the build failed with platform-specific errors:
```
/Users/darkis/Desktop/Working/Beam/Beam/Beam/Views/ContactInfoView.swift:39:31 
Cannot find 'NSColor' in scope

/Users/darkis/Desktop/Working/Beam/Beam/Beam/Views/ContactInfoView.swift:205:57 
Cannot find type 'NSImage' in scope

/Users/darkis/Desktop/Working/Beam/Beam/Beam/Views/ContactInfoView.swift:210:23 
Cannot find 'NSCIImageRep' in scope
```

## Root Cause
`ContactInfoView.swift` was using macOS-specific (AppKit) classes:
- `NSColor` - macOS only
- `NSImage` - macOS only  
- `NSCIImageRep` - macOS only

iOS uses UIKit equivalents:
- `UIColor` - iOS
- `UIImage` - iOS
- Core Graphics for QR code generation

## Solution
Added proper platform-specific code using `#if os(macOS)` / `#else` conditionals.

### Changes Made

#### 1. Added Platform Imports
```swift
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
```

#### 2. Fixed Color References
**Before:**
```swift
.background(Color(NSColor.textBackgroundColor))
.background(Color(NSColor.controlBackgroundColor))
```

**After:**
```swift
#if os(macOS)
.background(Color(NSColor.textBackgroundColor))
#else
.background(Color(UIColor.systemBackground))
#endif

#if os(macOS)
.background(Color(NSColor.controlBackgroundColor))
#else
.background(Color(UIColor.secondarySystemBackground))
#endif
```

#### 3. Fixed Image Display
**Before:**
```swift
Image(nsImage: generateQRCode(from: contact.id))
    .interpolation(.none)
    .resizable()
```

**After:**
```swift
Group {
    #if os(macOS)
    Image(nsImage: generateQRCode(from: contact.id))
        .interpolation(.none)
        .resizable()
        .scaledToFit()
    #else
    Image(uiImage: generateQRCode(from: contact.id))
        .interpolation(.none)
        .resizable()
        .scaledToFit()
    #endif
}
.frame(width: 240, height: 240)
.padding()
```

Note: Used `Group` to wrap platform-specific Image initializers so common modifiers can be applied outside.

#### 4. Dual QR Code Generation Functions
**macOS Version:**
```swift
#if os(macOS)
private func generateQRCode(from string: String) -> NSImage {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    
    if let outputImage = filter.outputImage {
        let rep = NSCIImageRep(ciImage: outputImage)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
    
    return NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil) ?? NSImage()
}
#else
```

**iOS Version:**
```swift
private func generateQRCode(from string: String) -> UIImage {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    
    if let outputImage = filter.outputImage {
        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
    }
    
    return UIImage(systemName: "xmark.circle") ?? UIImage()
}
#endif
```

Key differences:
- **macOS**: Uses `NSCIImageRep` to create `NSImage`
- **iOS**: Uses `CIContext` and `CGImage` to create `UIImage`, with 10x scaling for better quality

## Platform Mapping

| macOS (AppKit) | iOS (UIKit) | SwiftUI |
|---|---|---|
| `NSColor.textBackgroundColor` | `UIColor.systemBackground` | `Color()` wrapper |
| `NSColor.controlBackgroundColor` | `UIColor.secondarySystemBackground` | `Color()` wrapper |
| `NSImage` | `UIImage` | `Image(nsImage:)` / `Image(uiImage:)` |
| `NSCIImageRep` | `CIContext` + `CGImage` | - |
| `systemSymbolName:` | `systemName:` | - |

## Build Results

✅ **iOS (iPhone 14 Simulator):**
```
** BUILD SUCCEEDED **
```

✅ **macOS:**
```
** BUILD SUCCEEDED **
```

## Testing Checklist

### iOS
- [ ] Contact info view opens without crash
- [ ] QR code displays correctly
- [ ] Colors match iOS system theme (light/dark mode)
- [ ] Delete chat works on iOS

### macOS  
- [ ] Contact info view still works
- [ ] QR code displays correctly
- [ ] Colors match macOS system theme
- [ ] Delete chat works on macOS

## Files Modified

1. **ContactInfoView.swift**
   - Added UIKit/AppKit imports
   - Added 7 platform-specific color conditionals
   - Fixed Image initialization with Group wrapper
   - Created dual QR code generation functions
   - Total changes: ~40 lines modified

## Lessons Learned

1. **Always use platform conditionals** for UI code that needs to run on both iOS and macOS
2. **Group wrapper** is useful when you need platform-specific view initializers but common modifiers
3. **Color mappings**:
   - macOS: `textBackgroundColor`, `controlBackgroundColor`
   - iOS: `systemBackground`, `secondarySystemBackground`
4. **Image generation** differs significantly:
   - macOS has native `NSCIImageRep` support
   - iOS requires `CIContext` and manual scaling
5. **SF Symbols**: macOS uses `systemSymbolName:`, iOS uses `systemName:`

## Notes

- SwiftUI's `Color()` can wrap both `NSColor` and `UIColor`, making it easy to support both platforms
- The `#if os(macOS)` / `#else` pattern works for any platform-specific code
- Using `Group` allows sharing modifiers while keeping initializers platform-specific
- QR codes on iOS are scaled 10x for better resolution (CIFilter outputs small images by default)
