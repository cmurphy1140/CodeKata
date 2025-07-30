# Build & Deploy

## CI/CD Pipeline with GitHub Actions

### Complete Workflow Configuration

```yaml
# .github/workflows/ios-ci-cd.yml
name: iOS CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [published]

env:
  XCODE_VERSION: '15.0'
  IOS_SIMULATOR: 'iPhone 15 Pro'
  IOS_VERSION: '17.0'

jobs:
  test:
    name: Run Tests
    runs-on: macos-14
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_${{ env.XCODE_VERSION }}.app/Contents/Developer
    
    - name: Cache Swift Package Manager
      uses: actions/cache@v3
      with:
        path: |
          ~/Library/Developer/Xcode/DerivedData
          ~/.cache/org.swift.swiftpm
        key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
        restore-keys: |
          ${{ runner.os }}-spm-
    
    - name: Install dependencies
      run: xcodebuild -resolvePackageDependencies -project CodeKata.xcodeproj
    
    - name: Run SwiftLint
      run: |
        if which swiftlint >/dev/null; then
          swiftlint lint --reporter github-actions-logging
        else
          echo "SwiftLint not installed, installing..."
          brew install swiftlint
          swiftlint lint --reporter github-actions-logging
        fi
    
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project CodeKata.xcodeproj \
          -scheme CodeKata \
          -destination "platform=iOS Simulator,name=${{ env.IOS_SIMULATOR }},OS=${{ env.IOS_VERSION }}" \
          -resultBundlePath TestResults \
          -enableCodeCoverage YES \
          | xcpretty --report junit --output results.xml
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: Test Results
        path: |
          TestResults
          results.xml
    
    - name: Generate Code Coverage Report
      run: |
        xcrun xccov view --report --json TestResults.xcresult > coverage.json
        xcrun xccov view --report TestResults.xcresult
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage.json
        fail_ci_if_error: true

  build:
    name: Build App
    runs-on: macos-14
    needs: test
    if: github.ref == 'refs/heads/main' || github.event_name == 'release'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_${{ env.XCODE_VERSION }}.app/Contents/Developer
    
    - name: Import Code Signing Certificates
      uses: apple-actions/import-codesign-certs@v2
      with:
        p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
        p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
    
    - name: Install Provisioning Profiles
      uses: apple-actions/download-provisioning-profiles@v2
      with:
        bundle-id: com.codekata.challenges
        profile-type: IOS_APP_STORE
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
    
    - name: Increment Build Number
      run: |
        BUILD_NUMBER=$(expr $GITHUB_RUN_NUMBER + 1000)
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" CodeKata/Info.plist
        echo "BUILD_NUMBER=$BUILD_NUMBER" >> $GITHUB_ENV
    
    - name: Build Archive
      run: |
        xcodebuild archive \
          -project CodeKata.xcodeproj \
          -scheme CodeKata \
          -configuration Release \
          -destination generic/platform=iOS \
          -archivePath CodeKata.xcarchive \
          DEVELOPMENT_TEAM=${{ secrets.DEVELOPMENT_TEAM_ID }}
    
    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath CodeKata.xcarchive \
          -exportPath . \
          -exportOptionsPlist ExportOptions.plist
    
    - name: Upload to TestFlight
      if: github.ref == 'refs/heads/main'
      uses: apple-actions/upload-testflight-build@v1
      with:
        app-path: CodeKata.ipa
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
    
    - name: Upload to App Store
      if: github.event_name == 'release'
      uses: apple-actions/upload-appstore-build@v1
      with:
        app-path: CodeKata.ipa
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

  notify:
    name: Notify Team
    runs-on: ubuntu-latest
    needs: [test, build]
    if: always()
    
    steps:
    - name: Notify Slack on Success
      if: needs.test.result == 'success' && needs.build.result == 'success'
      uses: 8398a7/action-slack@v3
      with:
        status: success
        channel: '#ios-builds'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        
    - name: Notify Slack on Failure
      if: needs.test.result == 'failure' || needs.build.result == 'failure'
      uses: 8398a7/action-slack@v3
      with:
        status: failure
        channel: '#ios-builds'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Fastlane Configuration

### Complete Fastfile

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run all tests"
  lane :test do
    run_tests(
      project: "CodeKata.xcodeproj",
      scheme: "CodeKata",
      device: "iPhone 15 Pro",
      code_coverage: true,
      output_directory: "./fastlane/test_output"
    )
  end

  desc "Setup development environment"
  lane :setup_dev do
    ensure_xcode_version(version: "15.0")
    match(type: "development", readonly: false)
    spm(command: "resolve")
    
    update_code_signing_settings(
      use_automatic_signing: false,
      path: "CodeKata.xcodeproj",
      team_id: ENV["TEAM_ID"],
      code_sign_identity: "Apple Development",
      profile_name: "match Development com.codekata.challenges"
    )
    
    build_app(
      scheme: "CodeKata",
      configuration: "Debug",
      export_method: "development",
      skip_codesigning: false
    )
  end

  desc "Deploy to TestFlight"
  lane :beta do
    ensure_git_branch(branch: 'main')
    ensure_git_status_clean
    
    increment_build_number(
      build_number: latest_testflight_build_number + 1
    )
    
    build_app(
      project: "CodeKata.xcodeproj",
      scheme: "CodeKata",
      configuration: "Release",
      export_method: "app-store"
    )
    
    upload_to_testflight(
      changelog: "Bug fixes and performance improvements",
      distribute_external: false,
      notify_external_testers: false
    )
    
    commit_version_bump(message: "Version Bump to #{get_version_number}")
    add_git_tag(tag: "v#{get_version_number}-#{get_build_number}")
    push_to_git_remote
    
    slack(
      message: "New CodeKata build #{get_version_number} (#{get_build_number}) uploaded to TestFlight! 🚀",
      success: true
    )
  end

  desc "Release to App Store"
  lane :release do
    app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_CONTENT"],
      duration: 1200,
      in_house: false
    )
    
    match(type: "appstore", readonly: is_ci)
    
    increment_version_number(
      version_number: ENV["VERSION"] || get_version_number
    )
    
    build_app(
      scheme: "CodeKata",
      workspace: "CodeKata.xcworkspace",
      configuration: "Release",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.codekata.challenges" => "match AppStore com.codekata.challenges"
        },
        uploadBitcode: false,
        uploadSymbols: true,
        compileBitcode: false
      },
      xcargs: "-allowProvisioningUpdates"
    )
    
    upload_to_app_store(
      force: true,
      reject_if_possible: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: ENV["SUBMIT_FOR_REVIEW"] == "true",
      automatic_release: false,
      submission_information: {
        add_id_info_limits_tracking: true,
        add_id_info_serves_ads: false,
        add_id_info_tracks_action: true,
        add_id_info_tracks_install: true,
        add_id_info_uses_idfa: false,
        content_rights_has_rights: true,
        content_rights_contains_third_party_content: false,
        export_compliance_platform: 'ios',
        export_compliance_compliance_required: false,
        export_compliance_encryption_updated: false,
        export_compliance_app_type: nil,
        export_compliance_uses_encryption: false,
        export_compliance_is_exempt: false,
        export_compliance_contains_third_party_cryptography: false,
        export_compliance_contains_proprietary_cryptography: false,
        export_compliance_available_on_french_store: false
      }
    )
    
    create_github_release(
      repository_name: "company/codekata-ios",
      api_token: ENV["GITHUB_TOKEN"],
      name: "v#{get_version_number}",
      tag_name: "v#{get_version_number}",
      description: File.read("CHANGELOG.md").split("\n## ")[1].split("\n## ")[0],
      commitish: "main",
      upload_assets: ["CodeKata.ipa"]
    )
    
    slack(
      message: "🚀 CodeKata v#{get_version_number} successfully submitted to App Store!",
      success: true,
      channel: "#ios-releases"
    ) if ENV["SLACK_URL"]
    
    clean_build_artifacts
  end

  desc "Generate new certificates"
  lane :certificates do
    match(
      type: "development",
      force: true,
      skip_confirmation: true
    )
    
    match(
      type: "appstore",
      force: true,
      skip_confirmation: true
    )
    
    match(
      type: "development",
      force_for_new_devices: true
    )
  end

  desc "Fix SPM build issues"
  lane :fix_spm do
    sh "rm -rf .build"
    sh "rm Package.resolved"
    
    spm(command: "reset")
    spm(command: "resolve")
    
    build_app(
      scheme: "CodeKata",
      xcargs: "-verbose",
      buildlog_path: "./build_logs"
    )
  end

  desc "Pre-submission validation"
  lane :validate_submission do
    verify_app_store_metadata(
      app_identifier: "com.codekata.challenges",
      username: ENV["APPLE_ID"]
    )
    
    build_app(
      scheme: "CodeKata",
      export_method: "app-store"
    )
    
    validate_app(
      app_path: "./CodeKata.ipa",
      username: ENV["APPLE_ID"]
    )
    
    ensure_app_store_compliance
  end

  error do |lane, exception|
    slack(
      message: "❌ Error in #{lane}: #{exception.message}",
      success: false,
      channel: "#ios-releases"
    ) if ENV["SLACK_URL"]
  end

  def ensure_app_store_compliance
    UI.important("Checking privacy manifest...")
    
    plist_path = "./CodeKata/Info.plist"
    plist = Plist.parse_xml(plist_path)
    
    required_keys = [
      "NSCameraUsageDescription",
      "NSLocationWhenInUseUsageDescription", 
      "NSUserTrackingUsageDescription"
    ]
    
    required_keys.each do |key|
      UI.error("Missing required key: #{key}") unless plist[key]
    end
  end
end
```

## Export Options Configuration

```xml
<!-- ExportOptions.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.codekata.challenges</key>
        <string>CodeKata Distribution Profile</string>
    </dict>
</dict>
</plist>
```

## Local Development Build Setup

### Prerequisites Installation

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install fastlane
brew install swiftlint
brew install git-lfs

# Install Ruby dependencies
bundle install

# Setup Git LFS for binary assets
git lfs install
```

### Development Environment Configuration

```bash
# Clone repository
git clone https://github.com/yourorg/codekata-ios.git
cd codekata-ios

# Setup development environment
bundle install
fastlane setup_dev

# Open project in Xcode
open CodeKata.xcodeproj
```

## Certificate Management

### Automated Certificate Setup with Match

```ruby
# Matchfile configuration
git_url("https://github.com/company/ios-certificates")
storage_mode("git")
app_identifier(["com.codekata.challenges", "com.codekata.challenges.extension"])
username("ios-dev@company.com")
team_id("ABC123DEF4")
```

### Manual Certificate Management

```bash
# Diagnose certificate issues
security find-identity -v -p codesigning

# Reset keychain if corrupted
security delete-keychain ~/Library/Keychains/login.keychain
security create-keychain -p "" ~/Library/Keychains/login.keychain
security default-keychain -s ~/Library/Keychains/login.keychain

# Clear provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

## Troubleshooting Common Build Issues

### Swift Package Manager Issues

```bash
# Clear SPM cache
rm -rf .build
rm Package.resolved

# Reset SPM
xcodebuild -resolvePackageDependencies -project CodeKata.xcodeproj

# If issues persist, delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Code Signing Issues

```bash
# Check current certificates
security find-identity -v -p codesigning

# Import certificate manually
security import certificate.p12 -k ~/Library/Keychains/login.keychain

# Update provisioning profiles
fastlane match development --force
fastlane match appstore --force
```

### Build Performance Issues

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset Xcode settings
defaults delete com.apple.dt.Xcode

# Increase build system memory
export XCODE_XCCONFIG_FILE="BuildSettings.xcconfig"
```

## App Store Submission Process

### Pre-submission Checklist

- [ ] All tests pass locally and in CI
- [ ] App Store Connect metadata is complete
- [ ] Privacy manifest is included
- [ ] App Store review guidelines compliance
- [ ] Screenshots and app preview videos uploaded
- [ ] App Store Connect agreement accepted

### Required Environment Variables

```bash
# GitHub Secrets Configuration
ASC_KEY_ID=your_app_store_connect_key_id
ASC_ISSUER_ID=your_issuer_id
ASC_KEY_CONTENT=your_private_key_content
CERTIFICATES_P12=base64_encoded_certificates
CERTIFICATES_PASSWORD=certificate_password
DEVELOPMENT_TEAM_ID=your_team_id
SLACK_WEBHOOK=your_slack_webhook_url
GITHUB_TOKEN=your_github_token
```

### App Store Connect API Key Setup

1. **Generate API Key**:
   - Log in to App Store Connect
   - Go to Users and Access > Keys
   - Generate new API key with Developer role

2. **Convert to Base64**:
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
   ```

3. **Add to GitHub Secrets**:
   - Repository Settings > Secrets and Variables > Actions
   - Add ASC_KEY_CONTENT with base64 value

## Deployment Environments

### Development
- **Branch**: `develop`
- **Deployment**: Manual via Xcode or `fastlane setup_dev`
- **Certificate**: Development
- **Purpose**: Local testing and development

### Staging/TestFlight
- **Branch**: `main`
- **Deployment**: Automatic via GitHub Actions
- **Certificate**: App Store Distribution
- **Purpose**: Internal testing and QA

### Production/App Store
- **Branch**: Release tags (`v*`)
- **Deployment**: Manual approval after TestFlight
- **Certificate**: App Store Distribution
- **Purpose**: Public release

## Monitoring and Alerting

### Build Notifications

```ruby
# Slack notification configuration
def notify_team(success:, message:)
  slack(
    message: message,
    success: success,
    channel: "#ios-builds",
    webhook_url: ENV["SLACK_WEBHOOK"],
    default_payloads: [:git_branch, :git_author, :last_git_commit_message],
    attachment_properties: {
      fields: [
        {
          title: "Build Number",
          value: get_build_number,
          short: true
        },
        {
          title: "Version",
          value: get_version_number,
          short: true
        }
      ]
    }
  )
end
```

### Build Status Monitoring

```yaml
# GitHub Actions status checks
- name: Update commit status
  uses: Sibz/github-status-action@v1
  with:
    authToken: ${{ secrets.GITHUB_TOKEN }}
    context: 'iOS Build'
    description: 'Build completed successfully'
    state: 'success'
    sha: ${{ github.sha }}
```

## Security Considerations

### Code Signing Security
- Store certificates in encrypted private repositories
- Use temporary keychain for CI builds
- Rotate certificates annually
- Use App Store Connect API keys instead of passwords

### Secrets Management
- Never commit certificates or private keys
- Use GitHub encrypted secrets
- Implement secret rotation policies
- Audit secret access regularly

## Performance Optimization

### Build Speed Optimization

```ruby
# Fastlane optimization
build_app(
  scheme: "CodeKata",
  configuration: "Release",
  export_method: "app-store",
  build_path: "./build",
  derived_data_path: "./DerivedData",
  xcargs: "-parallelizeTargets -jobs 4"
)
```

### CI/CD Optimization

```yaml
# GitHub Actions caching
- name: Cache Xcode DerivedData
  uses: actions/cache@v3
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-xcode-${{ hashFiles('**/*.xcodeproj') }}
    restore-keys: |
      ${{ runner.os }}-xcode-
```

## Related Pages
- [[Configuration-Guide]] - Environment and build configuration
- [[Development-Environment]] - Local development setup
- [[Release-Process]] - Version management and releases
- [[Contributing-Guidelines]] - Development workflow guidelines