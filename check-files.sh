#!/bin/bash

# Beam Project File Verification Script
# This script checks which files exist and which are in Xcode

echo "🔍 Beam Project File Check"
echo "=========================="
echo ""

PROJECT_ROOT="/Users/darkis/Desktop/Working/Beam/Beam"
CODE_ROOT="$PROJECT_ROOT/Beam"

echo "📂 Checking if files exist on disk..."
echo ""

# Check Models
echo "Models:"
for file in Contact Message User ConnectionStatus; do
    if [ -f "$CODE_ROOT/Models/${file}.swift" ]; then
        echo "  ✅ ${file}.swift exists"
    else
        echo "  ❌ ${file}.swift missing"
    fi
done

echo ""

# Check Services
echo "Services:"
for file in DatabaseService EncryptionService RelayService GossipService MessageService; do
    if [ -f "$CODE_ROOT/Services/${file}.swift" ]; then
        echo "  ✅ ${file}.swift exists"
    else
        echo "  ❌ ${file}.swift missing"
    fi
done

echo ""

# Check Views
echo "Views:"
for file in ChatListView ChatView ContactsView MyQRCodeView ScanQRCodeView SettingsView; do
    if [ -f "$CODE_ROOT/Views/${file}.swift" ]; then
        echo "  ✅ ${file}.swift exists"
    else
        echo "  ❌ ${file}.swift missing"
    fi
done

echo ""

# Check Components
echo "Components:"
for file in AvatarView ConnectionStatusView; do
    if [ -f "$CODE_ROOT/Components/${file}.swift" ]; then
        echo "  ✅ ${file}.swift exists"
    else
        echo "  ❌ ${file}.swift missing"
    fi
done

echo ""

# Check Utilities
echo "Utilities:"
for file in BeamColors DateExtensions; do
    if [ -f "$CODE_ROOT/Utilities/${file}.swift" ]; then
        echo "  ✅ ${file}.swift exists"
    else
        echo "  ❌ ${file}.swift missing"
    fi
done

echo ""
echo "=========================="
echo ""
echo "🎯 NEXT STEP: Add files to Xcode"
echo ""
echo "Since files exist but Xcode can't see them, you need to:"
echo ""
echo "1. In Xcode, go to Project Navigator (press ⌘1)"
echo "2. Right-click on 'Beam' folder"
echo "3. Select 'Add Files to Beam...'"
echo "4. Navigate to: $CODE_ROOT"
echo "5. Select folders: Models, Services, Views, Components, Utilities"
echo "6. Make sure to check:"
echo "   ✅ Copy items if needed"
echo "   ✅ Create groups (NOT folder references)"
echo "   ✅ Add to targets: Beam (checked)"
echo "7. Click 'Add'"
echo ""
echo "Then press ⌘⇧K (Clean) and ⌘B (Build)"
echo ""
