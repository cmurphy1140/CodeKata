# Contributing Guidelines

## Welcome Contributors!

Thank you for your interest in contributing to CodeKata iOS! This guide will help you get started with contributing to our coding challenge app.

## Getting Started

### 1. Fork and Clone
```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/yourusername/codekata-ios.git
cd codekata-ios

# Add upstream remote
git remote add upstream https://github.com/company/codekata-ios.git
```

### 2. Setup Development Environment
```bash
# Install dependencies
bundle install

# Setup development environment
fastlane setup_dev

# Open project in Xcode
open CodeKata.xcodeproj
```

### 3. Create Feature Branch
```bash
# Ensure you're on main and up to date
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/add-new-challenge-type
git push -u origin feature/add-new-challenge-type
```

## Development Workflow

### Code Standards

#### Swift Style Guidelines
Follow [Apple's API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and our project-specific standards:

- Maximum line length: 120 characters
- Use meaningful variable and function names
- Include documentation comments for public APIs
- Follow SwiftLint configuration (`.swiftlint.yml`)

#### Code Organization
```swift
// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindViewModel()
}

// MARK: - Setup
private func setupUI() {
    // UI setup code
}

private func bindViewModel() {
    // ViewModel binding
}

// MARK: - Actions
@IBAction private func submitButtonTapped(_ sender: UIButton) {
    // Action implementation
}

// MARK: - Private Methods
private func handleValidationResult(_ result: ValidationResult) {
    // Private method implementation
}
```

### Architecture Patterns

#### MVVM with @Observable
```swift
// ViewModel
@Observable
class ChallengeListViewModel {
    private(set) var challenges: [Challenge] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private let challengeService: ChallengeService
    
    init(challengeService: ChallengeService = DefaultChallengeService()) {
        self.challengeService = challengeService
    }
    
    @MainActor
    func loadChallenges() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            challenges = try await challengeService.fetchChallenges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// SwiftUI View
struct ChallengeListView: View {
    @State private var viewModel = ChallengeListViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.challenges) { challenge in
                ChallengeRowView(challenge: challenge)
            }
            .refreshable {
                await viewModel.loadChallenges()
            }
            .task {
                await viewModel.loadChallenges()
            }
        }
    }
}
```

## Pull Request Process

### Before Submitting

**Pre-submission Checklist:**
- [ ] All tests pass locally (`fastlane test`)
- [ ] SwiftLint shows no warnings or errors
- [ ] Code is self-reviewed
- [ ] Documentation updated (if applicable)
- [ ] Screenshots included for UI changes
- [ ] Breaking changes documented

### PR Requirements

#### 1. Descriptive Title and Summary
```
feat(challenges): Add algorithm visualization feature

- Implement interactive visualization for sorting algorithms
- Add step-by-step animation controls
- Include performance metrics display
- Add accessibility support for VoiceOver

Closes #123
```

#### 2. PR Template
```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed
- [ ] Tested on multiple device sizes

## Screenshots (if applicable)
Include before/after screenshots for UI changes.

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

1. **Automated Checks**: Must pass before human review
   - CI/CD pipeline tests
   - SwiftLint code quality checks
   - Build validation

2. **Code Review**: At least one approval required
   - Focus on code quality, architecture, and maintainability
   - Address all review feedback
   - Resolve conversations before merge

3. **Maintainer Approval**: Final approval from project maintainer

## Testing Guidelines

### Unit Tests
```swift
import Testing
@testable import CodeKata

@Suite("Challenge Manager Tests")
struct ChallengeManagerTests {
    var sut: ChallengeManager!
    var mockRepository: MockChallengeRepository!
    
    init() {
        mockRepository = MockChallengeRepository()
        sut = ChallengeManager(repository: mockRepository)
    }
    
    @Test("Load challenges returns correct data")
    func testLoadChallenges_Success_ReturnsData() async throws {
        // Given
        let expectedChallenges = [Challenge.sample]
        mockRepository.mockChallenges = expectedChallenges
        
        // When
        let challenges = try await sut.loadChallenges(difficulty: .whiteBelt)
        
        // Then
        #expect(challenges.count == 1)
        #expect(challenges.first?.title == "Sample Challenge")
    }
    
    @Test("Load challenges handles error")
    func testLoadChallenges_Error_ThrowsError() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When/Then
        await #expect(throws: ChallengeError.networkError) {
            try await sut.loadChallenges(difficulty: .whiteBelt)
        }
    }
}
```

### UI Tests
```swift
class CodeKataUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testChallengeListNavigation() throws {
        // Given
        let challengeList = app.tables["ChallengeList"]
        XCTAssertTrue(challengeList.waitForExistence(timeout: 5))
        
        // When
        challengeList.cells.firstMatch.tap()
        
        // Then
        let challengeDetail = app.otherElements["ChallengeDetail"]
        XCTAssertTrue(challengeDetail.waitForExistence(timeout: 5))
    }
}
```

### Test Coverage Requirements
- **Minimum Coverage**: 80% for new code
- **Critical Paths**: 95% coverage required
- **UI Components**: Focus on user interaction flows
- **Business Logic**: Comprehensive unit test coverage

## Code Review Checklist

### For Authors

**Code Quality:**
- [ ] Code follows Swift style guidelines
- [ ] Proper error handling implemented
- [ ] No force unwrapping (!) unless absolutely necessary
- [ ] Memory management considered (weak/unowned references)
- [ ] Performance implications assessed
- [ ] Security considerations addressed

**Architecture:**
- [ ] Follows MVVM pattern
- [ ] Proper separation of concerns
- [ ] Dependency injection used appropriately
- [ ] Protocol-oriented design where applicable

**Testing:**
- [ ] Unit tests cover new functionality
- [ ] UI tests added for user-facing features
- [ ] Edge cases considered and tested
- [ ] Mock objects used for external dependencies

### For Reviewers

**Logic Review:**
- [ ] Logic is correct and efficient
- [ ] Edge cases handled appropriately
- [ ] Error conditions managed properly
- [ ] Business requirements fulfilled

**Code Quality:**
- [ ] Code is readable and maintainable
- [ ] Appropriate abstractions used
- [ ] No code duplication
- [ ] Consistent with project patterns

**Testing:**
- [ ] Tests are meaningful and comprehensive
- [ ] Test names clearly describe scenarios
- [ ] Proper setup and teardown
- [ ] Tests are isolated and deterministic

## Types of Contributions

### Bug Fixes
1. **Identify Issue**: Link to existing issue or create one
2. **Reproduce Locally**: Ensure you can reproduce the bug
3. **Fix Implementation**: Minimal change to resolve issue
4. **Add Tests**: Prevent regression
5. **Update Documentation**: If behavior changes

### New Features
1. **Feature Discussion**: Open issue to discuss feature
2. **Design Review**: Architecture and API design
3. **Implementation**: Follow established patterns
4. **Comprehensive Testing**: Unit and integration tests
5. **Documentation**: Update relevant documentation

### Documentation Improvements
1. **Identify Gap**: Missing or unclear documentation
2. **Improve Clarity**: Make documentation more accessible
3. **Add Examples**: Include code examples where helpful
4. **Update Links**: Ensure all links are working

### Performance Improvements
1. **Identify Bottleneck**: Profile and measure performance
2. **Propose Solution**: Discuss approach with maintainers
3. **Implement Changes**: Maintain existing behavior
4. **Measure Impact**: Quantify performance improvement
5. **Add Benchmarks**: Prevent performance regression

## Issue Reporting

### Bug Reports
```markdown
**Bug Description**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected Behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - Device: [e.g. iPhone 15 Pro]
 - OS: [e.g. iOS 17.2]
 - App Version: [e.g. 2.1.0]

**Additional Context**
Add any other context about the problem here.
```

### Feature Requests
```markdown
**Feature Summary**
A clear and concise description of what the feature should do.

**Problem Statement**
What problem does this feature solve?

**Proposed Solution**
A clear and concise description of what you want to happen.

**Alternatives Considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional Context**
Add any other context or screenshots about the feature request here.
```

## Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn and contribute
- Maintain professional communication

### Communication Channels
- **Issues**: Bug reports and feature requests
- **Discussions**: General questions and ideas
- **Pull Requests**: Code contributions and reviews
- **Wiki**: Documentation improvements

## Recognition

Contributors will be recognized in:
- **CONTRIBUTORS.md**: List of all contributors
- **Release Notes**: Major contributions highlighted
- **README**: Core maintainers and contributors
- **GitHub**: Contributor insights and statistics

## Related Pages
- [[Coding-Standards]] - Detailed coding style guidelines
- [[Git-Workflow]] - Branching and commit conventions
- [[Testing-Strategy]] - Comprehensive testing approach
- [[Code-Quality]] - Quality assurance processes