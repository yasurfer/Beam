# Beam - Production Deployment Guide

## 📱 Platform Options

### 1. **macOS App Store**
- Easiest distribution for Mac users
- Requires Apple Developer Program ($99/year)
- Apple reviews your app (1-7 days)

### 2. **Direct Download (macOS)**
- Distribute via your website
- Requires code signing & notarization
- More flexible but users see security warnings if not notarized

### 3. **iOS App Store**
- Required for iPhone/iPad distribution
- Requires Apple Developer Program ($99/year)
- Stricter review process

### 4. **TestFlight (Beta Testing)**
- Free beta distribution
- Up to 10,000 testers
- Good for testing before public release

---

## ✅ Pre-Production Checklist

### **1. App Configuration**
- [ ] Update Bundle Identifier (e.g., `com.yourcompany.beam`)
- [ ] Set Marketing Version (e.g., `1.0.0`)
- [ ] Set Build Number (start with `1`)
- [ ] Add all app icon sizes (1024×1024 for macOS)
- [ ] Add app logo to Assets (if using custom logo)

### **2. Privacy & Legal**
- [x] Add camera usage description (Info.plist) ✓
- [x] Add network usage description (Info.plist) ✓
- [ ] Create Privacy Policy
- [ ] Create Terms of Service
- [ ] Add EULA if needed
- [ ] Copyright notice in About section

### **3. Code Cleanup**
- [x] Sample data only in DEBUG builds ✓
- [ ] Remove all `print()` debug statements or wrap in `#if DEBUG`
- [ ] Remove TODO/FIXME comments
- [ ] Add proper error handling
- [ ] Add analytics (optional: Firebase, Mixpanel)
- [ ] Add crash reporting (optional: Crashlytics, Sentry)

### **4. Security**
- [ ] Enable hardened runtime
- [ ] Enable app sandboxing
- [ ] Review entitlements (camera, network, file access)
- [ ] Implement proper keychain storage for sensitive data
- [ ] Add certificate pinning for network requests (if applicable)

### **5. Features**
- [ ] User onboarding flow
- [ ] First-time setup wizard
- [ ] Help/Documentation
- [ ] Contact support option
- [ ] Rate the app prompt
- [ ] Check for updates mechanism

### **6. Testing**
- [ ] Test on clean install (no existing data)
- [ ] Test upgrade from previous version (if applicable)
- [ ] Test on different macOS/iOS versions
- [ ] Test on different devices (Mac Intel/Apple Silicon, various iPhones)
- [ ] Test network interruptions
- [ ] Test low storage scenarios
- [ ] Beta test with real users (TestFlight)

---

## 🔧 Building for Production

### **1. Archive the App**
1. In Xcode, select **Product → Archive**
2. Wait for build to complete
3. Xcode Organizer will open

### **2. Code Signing**
- You need an **Apple Developer Account** ($99/year)
- Create certificates and provisioning profiles in Apple Developer portal
- Xcode can manage this automatically ("Automatically manage signing")

### **3. Distribution Options**

#### **Option A: App Store (Recommended)**
1. In Organizer, click **Distribute App**
2. Choose **App Store Connect**
3. Follow wizard to upload
4. Go to [App Store Connect](https://appstoreconnect.apple.com)
5. Fill in app metadata:
   - Screenshots
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL
6. Submit for review

#### **Option B: Direct Distribution (macOS)**
1. In Organizer, click **Distribute App**
2. Choose **Developer ID**
3. Export signed app
4. Notarize with Apple:
   ```bash
   xcrun notarytool submit Beam.app --apple-id your@email.com --team-id TEAMID --password app-specific-password
   ```
5. Staple notarization:
   ```bash
   xcrun stapler staple Beam.app
   ```
6. Create DMG or ZIP for distribution

---

## 📄 App Store Submission Requirements

### **Metadata Required:**
- [ ] App Name (30 characters max)
- [ ] Subtitle (optional, 30 characters)
- [ ] Description (4000 characters)
- [ ] Keywords (100 characters, comma-separated)
- [ ] Support URL
- [ ] Privacy Policy URL
- [ ] Screenshots (at least 3-5 per platform)
- [ ] App Preview Video (optional but recommended)
- [ ] Age Rating
- [ ] Category (Social Networking / Utilities)
- [ ] Pricing (Free or Paid)

### **Screenshots Sizes (macOS):**
- 1280 x 800
- 1440 x 900
- 2560 x 1600
- 2880 x 1800

### **Screenshots Sizes (iOS):**
- iPhone: 6.5" display (1284 x 2778)
- iPad: 12.9" display (2048 x 2732)

---

## 🚨 Common Rejection Reasons

1. **Missing functionality** - All advertised features must work
2. **Crashes** - App must be stable
3. **Privacy violations** - Must have privacy policy
4. **Misleading content** - Screenshots must be accurate
5. **Incomplete metadata** - All required fields must be filled
6. **Poor user experience** - App must be polished
7. **Guideline violations** - Read [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 📊 Post-Launch

### **Analytics to Track:**
- Daily/Monthly Active Users (DAU/MAU)
- Retention rates (Day 1, 7, 30)
- Crash rate
- Feature usage
- User feedback/reviews

### **Marketing:**
- Create website/landing page
- Social media presence
- Product Hunt launch
- Press release
- Reddit communities
- Tech blogs outreach

### **Support:**
- Setup support email
- Create FAQ/Help Center
- Monitor App Store reviews
- Respond to user feedback

---

## 💰 Costs

### **One-Time:**
- Apple Developer Program: $99/year
- Designer for icons/screenshots: $100-500 (optional)
- Website/Domain: $10-50/year (optional)

### **Ongoing (Optional):**
- Analytics service: $0-100/month
- Crash reporting: $0-50/month
- Cloud backend: $0-100/month (if you add cloud features)
- Customer support tools: $0-50/month

---

## 🔗 Useful Resources

- [Apple Developer](https://developer.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight](https://developer.apple.com/testflight/)

---

## 📝 Next Steps

1. **Create Apple Developer Account** at developer.apple.com
2. **Complete this checklist** item by item
3. **Build and test** thoroughly
4. **Submit to TestFlight** for beta testing
5. **Get feedback** from beta testers
6. **Polish based on feedback**
7. **Submit to App Store**
8. **Market your app!**

---

## ⚠️ Important Notes

- **Review times**: 1-7 days typically
- **Rejections are normal**: Average app gets rejected 1-2 times
- **Be patient**: Quality over speed
- **Communicate**: Respond to review feedback quickly
- **Stay updated**: Apple guidelines change regularly

Good luck with your launch! 🚀
