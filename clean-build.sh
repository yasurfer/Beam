#!/bin/zsh
# Quick fix script for iPhone launch error

echo "🧹 Cleaning Xcode build data..."

# Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Beam-*

echo "✅ DerivedData cleaned"
echo ""
echo "📱 Next steps:"
echo "1. Delete Beam app from iPhone 6s (long press icon > Delete)"
echo "2. Restart your iPhone 6s"
echo "3. In Xcode: Product > Clean Build Folder (Shift+Cmd+K)"
echo "4. In Xcode: Window > Devices and Simulators"
echo "   - Make sure iPhone 6s shows 'Ready' status"
echo "   - If using wireless, try connecting via USB cable instead"
echo "5. Select iPhone 6s as destination"
echo "6. Product > Build (Cmd+B)"
echo "7. Product > Run (Cmd+R)"
echo ""
echo "⚠️  IMPORTANT: On first launch, tap 'Allow' when iOS asks for Local Network permission!"
