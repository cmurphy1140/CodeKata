# Coding Standards

## Swift Coding Standards for CodeKata

This document outlines the coding standards and conventions for the CodeKata iOS project. Following these standards ensures consistency, readability, and maintainability across the codebase.

## Naming Conventions

### Variables and Functions
```swift
// GOOD - Clear, descriptive names
let challengeCompletionRate = 0.85
let userProgressData = UserProgress()
var isLoadingChallenges = false

func calculateScoreForChallenge(_ challenge: Challenge) -> Double {
    // Implementation
}

func loadNextAvailableChallenge() async throws -> Challenge? {
    // Implementation
}

// AVOID - Abbreviated or unclear names
let ccr = 0.85  // What does 'ccr' mean?
let upd = UserProgress()  // Unclear abbreviation
var loading = false  // Loading what?

func calcScore(_ c: Challenge) -> Double {  // Unclear abbreviations
    // Implementation
}
```

### Types and Protocols
```swift
// GOOD - PascalCase for types
class ChallengeViewController: UIViewController { }
struct UserProgressData { }
enum DifficultyLevel { }
protocol ChallengeValidating { }

// Protocol naming
protocol ChallengeManagerDelegate: AnyObject { }  // Delegate protocols
protocol Validatable { }  // Capability protocols (-able, -ing suffix)

// AVOID - Incorrect casing
class challengeViewController { }  // Should be PascalCase
struct userProgressData { }      // Should be PascalCase
```

### Constants and Enums
```swift
// GOOD - Constants
private let maxRetryAttempts = 3
private let defaultTimeoutInterval: TimeInterval = 30.0

static let shared = NetworkManager()

// Enum cases - camelCase
enum ChallengeType {
    case algorithm
    case dataStructure
    case systemDesign
    case dynamicProgramming
}

// AVOID - All caps for constants (this is not Swift style)
private let MAX_RETRY_ATTEMPTS = 3  // Should be camelCase
```

## SwiftLint Configuration

### .swiftlint.yml
```yaml
disabled_rules:
  - trailing_whitespace
  - force_cast

opt_in_rules:
  - array_init
  - closure_spacing
  - empty_count
  - empty_string
  - explicit_init
  - first_where
  - sorted_first_last
  - weak_delegate
  - operator_usage_whitespace
  - vertical_parameter_alignment_on_call

included:
  - Sources
  - CodeKata
  - Tests

excluded:
  - Carthage
  - Pods
  - DerivedData
  - Generated
  - .build

# Rule configurations
line_length:
  warning: 120
  error: 150
  ignores_urls: true
  ignores_function_declarations: true
  ignores_comments: true

function_body_length:
  warning: 50
  error: 100

function_parameter_count:
  warning: 5
  error: 8

type_body_length:
  warning: 300
  error: 500

cyclomatic_complexity:
  warning: 10
  error: 20

identifier_name:
  min_length: 2
  max_length: 60
  excluded:
    - id
    - ok
    - to
    - of
    - in
    - at
    - x
    - y

custom_rules:
  comments_space:
    name: "Space After Comment"
    regex: '(^ *//\w+)'
    message: "There should be a space after //"
    severity: warning
  
  empty_first_line:
    name: "Empty First Line"
    regex: '(^[ a-zA-Z ]*(?:protocol|extension|class|struct) (?!.*\{[ a-zA-Z]*\}$).*\{\n *\S+)'
    message: "There should be an empty line after a declaration"
    severity: warning
```

## Architecture Patterns

### MVVM Implementation
```swift
// ViewModel - Use @Observable for iOS 17+
@Observable
class ChallengeListViewModel {
    // MARK: - Published Properties
    private(set) var challenges: [Challenge] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private let challengeService: ChallengeService
    private let analyticsService: AnalyticsService
    
    // MARK: - Initialization
    init(
        challengeService: ChallengeService = DefaultChallengeService(),
        analyticsService: AnalyticsService = DefaultAnalyticsService()
    ) {
        self.challengeService = challengeService
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Methods
    @MainActor
    func loadChallenges(difficulty: DifficultyLevel) async {
        isLoading = true
        errorMessage = nil
        
        do {
            challenges = try await challengeService.fetchChallenges(difficulty: difficulty)
            analyticsService.track(.challengesLoaded(count: challenges.count))
        } catch {
            errorMessage = error.localizedDescription
            analyticsService.track(.challengesLoadError(error: error))
        }
        
        isLoading = false
    }
    
    func refreshChallenges() async {
        await loadChallenges(difficulty: .whiteBelt) // Default difficulty
    }
    
    // MARK: - Private Methods
    private func handleLoadingError(_ error: Error) {
        // Error handling logic
    }
}

// SwiftUI View
struct ChallengeListView: View {
    @State private var viewModel = ChallengeListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading challenges...")
                } else {
                    challengesList
                }
            }
            .navigationTitle("Challenges")
            .task {
                await viewModel.loadChallenges(difficulty: .whiteBelt)
            }
            .refreshable {
                await viewModel.refreshChallenges()
            }
        }
    }
    
    @ViewBuilder
    private var challengesList: some View {
        List(viewModel.challenges) { challenge in
            ChallengeRowView(challenge: challenge)
        }
        .listStyle(.insetGrouped)
    }
}
```

### Protocol-Oriented Programming
```swift
// GOOD - Protocol with default implementations
protocol Validatable {
    func validate() throws
}

extension Validatable {
    func isValid() -> Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
}

// GOOD - Composition over inheritance
protocol NetworkRequestable {
    var endpoint: String { get }
    var method: HTTPMethod { get }
}

protocol AuthenticationRequired {
    var requiresAuthentication: Bool { get }
}

struct ChallengeRequest: NetworkRequestable, AuthenticationRequired {
    let endpoint = "/api/challenges"
    let method: HTTPMethod = .GET
    let requiresAuthentication = true
}

// AVOID - Deep inheritance hierarchies
class BaseViewController: UIViewController { }
class NetworkViewController: BaseViewController { }
class ChallengeViewController: NetworkViewController { }  // Too deep
```

## Error Handling

### Error Types
```swift
// GOOD - Specific error types
enum ChallengeError: Error, LocalizedError {
    case networkError(underlying: Error)
    case validationFailed(reason: String)
    case challengeNotFound(id: String)
    case invalidDifficulty
    
    var errorDescription: String? {
        switch self {
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .challengeNotFound(let id):
            return "Challenge with ID \(id) not found"
        case .invalidDifficulty:
            return "Invalid difficulty level specified"
        }
    }
}

// GOOD - Error handling patterns
func loadChallenge(id: String) async throws -> Challenge {
    do {
        let challenge = try await challengeService.fetchChallenge(id: id)
        return challenge
    } catch let networkError as NetworkError {
        throw ChallengeError.networkError(underlying: networkError)
    } catch {
        throw ChallengeError.challengeNotFound(id: id)
    }
}

// GOOD - Result type for non-throwing functions
func validateSolution(_ code: String) -> Result<ValidationResult, ValidationError> {
    guard !code.isEmpty else {
        return .failure(.emptyCode)
    }
    
    // Validation logic
    let result = performValidation(code)
    return .success(result)
}
```

### Optional Handling
```swift
// GOOD - Safe optional unwrapping
guard let challenge = challenges.first else {
    return
}

// GOOD - Optional binding
if let user = currentUser {
    updateUserProgress(user)
}

// GOOD - Nil coalescing
let displayName = user.name ?? "Anonymous"

// AVOID - Force unwrapping
let challenge = challenges.first!  // Dangerous - can crash

// AVOID - Excessive optional chaining
user?.profile?.settings?.notifications?.enabled = true  // Hard to debug
```

## Memory Management

### Reference Cycles
```swift
// GOOD - Weak references for delegates
protocol ChallengeDelegate: AnyObject {
    func challengeDidComplete(_ challenge: Challenge)
}

class ChallengeManager {
    weak var delegate: ChallengeDelegate?
}

// GOOD - Weak self in closures
class ViewController: UIViewController {
    func loadData() {
        networkService.fetchData { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.updateUI(with: data)
            case .failure(let error):
                self.showError(error)
            }
        }
    }
}

// GOOD - Unowned for guaranteed lifetime
class Challenge {
    unowned let manager: ChallengeManager  // Manager always outlives Challenge
    
    init(manager: ChallengeManager) {
        self.manager = manager
    }
}
```

## Code Organization

### File Structure
```swift
// MARK: - Import Statements
import SwiftUI
import Combine

// MARK: - Type Definition
struct ChallengeDetailView: View {
    
    // MARK: - Properties
    let challenge: Challenge
    @State private var isCompleted = false
    @State private var userSolution = ""
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                challengeHeader
                challengeDescription
                solutionEditor
                submitButton
            }
            .padding()
        }
        .navigationTitle(challenge.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - View Components
    private var challengeHeader: some View {
        HStack {
            Text(challenge.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            DifficultyBadge(difficulty: challenge.difficulty)
        }
    }
    
    private var challengeDescription: some View {
        Text(challenge.description)
            .font(.body)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Actions
    private func submitSolution() {
        // Implementation
    }
    
    private func validateInput() -> Bool {
        // Implementation
        return true
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ChallengeDetailView(challenge: Challenge.sample)
    }
}
```

### Extension Organization
```swift
// MARK: - Main type definition
struct Challenge {
    let id: UUID
    let title: String
    let description: String
    let difficulty: DifficultyLevel
}

// MARK: - Computed Properties
extension Challenge {
    var displayTitle: String {
        "\(difficulty.emoji) \(title)"
    }
    
    var estimatedDuration: TimeInterval {
        switch difficulty {
        case .whiteBelt: return 300  // 5 minutes
        case .brownBelt: return 900  // 15 minutes
        case .blackBelt: return 1800 // 30 minutes
        }
    }
}

// MARK: - Protocol Conformance
extension Challenge: Identifiable {
    // Identifiable conformance (id property already exists)
}

extension Challenge: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data
extension Challenge {
    static let sample = Challenge(
        id: UUID(),
        title: "Two Sum",
        description: "Find two numbers in an array that add up to a target sum.",
        difficulty: .whiteBelt
    )
    
    static let sampleData: [Challenge] = [
        sample,
        Challenge(
            id: UUID(),
            title: "Binary Tree Traversal",
            description: "Implement in-order traversal of a binary tree.",
            difficulty: .brownBelt
        )
    ]
}
```

## Documentation Standards

### Code Comments
```swift
// GOOD - Clear, helpful comments
/// Calculates the user's score based on completion time and code quality.
/// 
/// - Parameters:
///   - completionTime: Time taken to solve the challenge in seconds
///   - codeQuality: Quality metrics including complexity and style
/// - Returns: Normalized score between 0.0 and 100.0
/// - Throws: `ScoringError.invalidInput` if parameters are invalid
func calculateScore(
    completionTime: TimeInterval,
    codeQuality: CodeQualityMetrics
) throws -> Double {
    guard completionTime > 0 else {
        throw ScoringError.invalidInput("Completion time must be positive")
    }
    
    // Base score starts at 100 points
    var score = 100.0
    
    // Apply time penalty (longer time = lower score)
    let timePenalty = min(completionTime / 60.0 * 5.0, 50.0)
    score -= timePenalty
    
    // Apply quality bonus (better code = higher score)
    let qualityBonus = codeQuality.overallScore * 20.0
    score += qualityBonus
    
    return max(0.0, min(100.0, score))
}

// AVOID - Redundant or unhelpful comments
// This function adds two numbers
func add(a: Int, b: Int) -> Int {
    return a + b  // Return the sum
}

// Bad variable name requiring comment
let x = 42  // User's current level
// Better: let currentUserLevel = 42
```

### Public API Documentation
```swift
/// A service responsible for managing coding challenges and user progress.
///
/// The `ChallengeManager` provides methods to load, validate, and track
/// user progress through coding challenges. It handles both online and
/// offline scenarios gracefully.
///
/// ## Usage
/// ```swift
/// let manager = ChallengeManager()
/// let challenges = try await manager.loadChallenges(difficulty: .whiteBelt)
/// ```
public class ChallengeManager {
    
    /// Loads challenges for the specified difficulty level.
    ///
    /// This method first attempts to load challenges from the local cache,
    /// then synchronizes with the server in the background to ensure
    /// up-to-date content.
    ///
    /// - Parameter difficulty: The difficulty level to filter challenges
    /// - Returns: An array of challenges matching the difficulty
    /// - Throws: `ChallengeError.networkError` if network fails and no cache exists
    public func loadChallenges(difficulty: DifficultyLevel) async throws -> [Challenge] {
        // Implementation
    }
}
```

## Testing Standards

### Unit Test Structure
```swift
import Testing
@testable import CodeKata

@Suite("Challenge Manager Tests")
struct ChallengeManagerTests {
    
    // MARK: - Properties
    var sut: ChallengeManager!
    var mockRepository: MockChallengeRepository!
    var mockAnalytics: MockAnalyticsService!
    
    // MARK: - Setup
    init() {
        mockRepository = MockChallengeRepository()
        mockAnalytics = MockAnalyticsService()
        sut = ChallengeManager(
            repository: mockRepository,
            analytics: mockAnalytics
        )
    }
    
    // MARK: - Success Cases
    @Test("Load challenges returns correct data for white belt")
    func testLoadChallenges_WhiteBelt_ReturnsCorrectData() async throws {
        // Given
        let expectedChallenges = [Challenge.whiteBeltSample]
        mockRepository.mockChallenges = expectedChallenges
        
        // When
        let challenges = try await sut.loadChallenges(difficulty: .whiteBelt)
        
        // Then
        #expect(challenges.count == 1)
        #expect(challenges.first?.difficulty == .whiteBelt)
        #expect(challenges.first?.title == "Two Sum")
    }
    
    @Test("Load challenges tracks analytics event")
    func testLoadChallenges_Success_TracksAnalytics() async throws {
        // Given
        mockRepository.mockChallenges = [Challenge.sample]
        
        // When
        _ = try await sut.loadChallenges(difficulty: .whiteBelt)
        
        // Then
        #expect(mockAnalytics.trackedEvents.count == 1)
        #expect(mockAnalytics.trackedEvents.first?.name == "challenges_loaded")
    }
    
    // MARK: - Error Cases
    @Test("Load challenges handles network error")
    func testLoadChallenges_NetworkError_ThrowsError() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = NetworkError.connectionFailed
        
        // When/Then
        await #expect(throws: ChallengeError.networkError) {
            try await sut.loadChallenges(difficulty: .whiteBelt)
        }
    }
    
    @Test("Load challenges tracks error analytics")
    func testLoadChallenges_Error_TracksErrorAnalytics() async throws {
        // Given
        mockRepository.shouldThrowError = true
        let expectedError = NetworkError.connectionFailed
        mockRepository.errorToThrow = expectedError
        
        // When
        do {
            _ = try await sut.loadChallenges(difficulty: .whiteBelt)
        } catch {
            // Expected to throw
        }
        
        // Then
        let errorEvents = mockAnalytics.trackedEvents.filter { $0.name == "challenges_load_error" }
        #expect(errorEvents.count == 1)
    }
}

// MARK: - Test Helpers
extension ChallengeManagerTests {
    func makeChallenge(difficulty: DifficultyLevel) -> Challenge {
        Challenge(
            id: UUID(),
            title: "Test Challenge",
            description: "A test challenge",
            difficulty: difficulty
        )
    }
}
```

### Mock Objects
```swift
// GOOD - Comprehensive mock with verification
class MockChallengeRepository: ChallengeRepositoryProtocol {
    
    // MARK: - Mock Configuration
    var mockChallenges: [Challenge] = []
    var shouldThrowError = false
    var errorToThrow: Error = NetworkError.connectionFailed
    
    // MARK: - Verification Properties
    private(set) var fetchChallengesCallCount = 0
    private(set) var lastFetchedDifficulty: DifficultyLevel?
    
    // MARK: - Protocol Implementation
    func fetchChallenges(difficulty: DifficultyLevel) async throws -> [Challenge] {
        fetchChallengesCallCount += 1
        lastFetchedDifficulty = difficulty
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockChallenges.filter { $0.difficulty == difficulty }
    }
    
    func fetchChallenge(id: String) async throws -> Challenge? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockChallenges.first { $0.id.uuidString == id }
    }
    
    // MARK: - Helper Methods
    func reset() {
        mockChallenges = []
        shouldThrowError = false
        fetchChallengesCallCount = 0
        lastFetchedDifficulty = nil
    }
}
```

## Performance Guidelines

### Lazy Loading
```swift
// GOOD - Lazy initialization for expensive operations
class ChallengeManager {
    private lazy var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 100
        return cache
    }()
    
    private lazy var complexProcessor: ComplexDataProcessor = {
        ComplexDataProcessor(configuration: .default)
    }()
}

// GOOD - Lazy view building in SwiftUI
struct ChallengeListView: View {
    @State private var challenges: [Challenge] = []
    
    var body: some View {
        NavigationView {
            LazyVStack {
                ForEach(challenges) { challenge in
                    ChallengeRowView(challenge: challenge)
                }
            }
        }
    }
}
```

### Background Processing
```swift
// GOOD - Background queue for heavy operations
class DataProcessor {
    private let processingQueue = DispatchQueue(
        label: "com.codekata.dataprocessing",
        qos: .utility,
        attributes: .concurrent
    )
    
    func processLargeDataSet(_ data: [DataItem]) async -> ProcessedData {
        return await withTaskGroup(of: ProcessedItem.self) { group in
            for item in data {
                group.addTask {
                    await self.processItem(item)
                }
            }
            
            var results: [ProcessedItem] = []
            for await result in group {
                results.append(result)
            }
            
            return ProcessedData(items: results)
        }
    }
    
    @MainActor
    func updateUI(with data: ProcessedData) {
        // UI updates must be on main thread
    }
}
```

## Security Best Practices

### Input Validation
```swift
// GOOD - Comprehensive input validation
struct ChallengeInput {
    let title: String
    let description: String
    let code: String
    
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard title.count <= 100 else {
            throw ValidationError.titleTooLong
        }
        
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyDescription
        }
        
        guard code.count <= 10000 else {
            throw ValidationError.codeTooLong
        }
        
        // Check for potentially dangerous patterns
        let dangerousPatterns = ["import os", "subprocess", "__import__"]
        for pattern in dangerousPatterns {
            guard !code.contains(pattern) else {
                throw ValidationError.unsafeCode(pattern: pattern)
            }
        }
    }
}
```

### Secure Storage
```swift
// GOOD - Keychain usage for sensitive data
import Security

class SecureStorage {
    enum Key: String, CaseIterable {
        case userToken = "user_auth_token"
        case apiKey = "api_key"
        case encryptionKey = "encryption_key"
    }
    
    func store(_ data: Data, for key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storageError(status)
        }
    }
    
    func retrieve(for key: Key) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrievalError(status)
        }
        
        return item as? Data
    }
}
```

## Accessibility Standards

### VoiceOver Support
```swift
// GOOD - Comprehensive accessibility support
struct ChallengeCard: View {
    let challenge: Challenge
    @State private var isCompleted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(challenge.title)
                .font(.headline)
            
            Text(challenge.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                DifficultyBadge(difficulty: challenge.difficulty)
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Tap to view challenge details and start solving")
        .accessibilityAction(.default) {
            // Navigate to challenge detail
        }
        .accessibilityAction(.escape) {
            // Handle escape gesture
        }
    }
    
    private var accessibilityDescription: String {
        var description = "Challenge: \(challenge.title). "
        description += "Difficulty: \(challenge.difficulty.rawValue). "
        if isCompleted {
            description += "Completed. "
        }
        description += challenge.description
        return description
    }
}
```

## Quality Assurance Tools

### Static Analysis Integration
```swift
// Build phase script for additional quality checks
#!/bin/bash

# SwiftLint
if which swiftlint >/dev/null; then
    swiftlint lint --reporter xcode
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

# SwiftFormat (if installed)
if which swiftformat >/dev/null; then
    swiftformat --lint .
fi

# Custom checks
echo "Running custom quality checks..."

# Check for TODO/FIXME comments in release builds
if [ "${CONFIGURATION}" == "Release" ]; then
    TAGS="TODO:|FIXME:|\\?\\?\\?:|\\!\\!\\!:"
    find "${SRCROOT}" \( -name "*.swift" \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "($TAGS).*\$" && exit 1
fi

echo "Quality checks completed successfully"
```

## Performance Monitoring

### Instruments Integration
```swift
// GOOD - Performance measurement points
import os.signpost

class PerformanceMonitor {
    private let log = OSLog(subsystem: "com.codekata.performance", category: "challenges")
    
    func measureChallengeLoading<T>(_ operation: () async throws -> T) async rethrows -> T {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "Challenge Loading", signpostID: signpostID)
        
        defer {
            os_signpost(.end, log: log, name: "Challenge Loading", signpostID: signpostID)
        }
        
        return try await operation()
    }
    
    func trackMemoryUsage() {
        let memoryInfo = mach_task_basic_info()
        var infoCount = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let status = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &infoCount)
            }
        }
        
        if status == KERN_SUCCESS {
            let memoryUsage = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            print("Memory usage: \(String(format: "%.2f", memoryUsage)) MB")
        }
    }
}
```

## Related Pages
- [[Contributing-Guidelines]] - Development workflow and contribution process
- [[Git-Workflow]] - Version control and branching strategies  
- [[Testing-Strategy]] - Comprehensive testing approaches
- [[Code-Quality]] - Quality assurance and review processes