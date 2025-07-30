# Git Workflow

## Branching Strategy (GitHub Flow)

We use a simplified GitHub Flow branching strategy that emphasizes continuous integration and deployment while maintaining code quality through pull requests.

### Branch Structure

```
main (production-ready)
├── feature/user-authentication
├── feature/challenge-editor
├── bugfix/memory-leak-fix
├── hotfix/critical-crash-fix
└── release/v2.1.0
```

### Branch Types

| Branch Type | Purpose | Naming Convention | Example |
|-------------|---------|------------------|---------|
| `main` | Production-ready code | `main` | `main` |
| `feature/*` | New features | `feature/description` | `feature/user-authentication` |
| `bugfix/*` | Bug fixes | `bugfix/description` | `bugfix/memory-leak-challenge-view` |
| `hotfix/*` | Critical production fixes | `hotfix/description` | `hotfix/crash-on-startup` |
| `release/*` | Release preparation | `release/version` | `release/v2.1.0` |

## Basic Workflow

### 1. Starting New Work

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create and switch to feature branch
git checkout -b feature/add-algorithm-category
git push -u origin feature/add-algorithm-category
```

### 2. Working on Feature

```bash
# Make changes and commit frequently
git add -A
git commit -m "feat(challenges): add algorithm category model"

# Push changes regularly
git push origin feature/add-algorithm-category

# Continue working with atomic commits
git add src/Views/AlgorithmCategoryView.swift
git commit -m "feat(ui): add algorithm category selection view"

git add src/Tests/AlgorithmCategoryTests.swift  
git commit -m "test(challenges): add algorithm category tests"
```

### 3. Preparing for Merge

```bash
# Rebase with main to get latest changes
git fetch origin
git rebase origin/main

# If conflicts exist, resolve them
git add resolved-file.swift
git rebase --continue

# Force push after rebase (safe for feature branches)
git push --force-with-lease origin feature/add-algorithm-category
```

### 4. Creating Pull Request

```bash
# Push final changes
git push origin feature/add-algorithm-category

# Create PR through GitHub UI or CLI
gh pr create --title "feat(challenges): Add algorithm category support" \
             --body "Adds support for algorithm categorization with UI and tests"
```

## Commit Message Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for consistent and meaningful commit messages.

### Format
```
<type>(<scope>): <description>

<body>

<footer>
```

### Types
- `feat`: New feature for the user
- `fix`: Bug fix for the user
- `docs`: Documentation changes
- `style`: Code formatting, no logic changes
- `refactor`: Code restructuring without feature changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `perf`: Performance improvements
- `ci`: CI/CD pipeline changes

### Scopes
- `challenges`: Challenge-related functionality
- `ui`: User interface components
- `auth`: Authentication system
- `gamification`: Scoring and achievements
- `editor`: Code editor functionality
- `validation`: Solution validation
- `data`: Data models and persistence
- `network`: Networking and API calls

### Examples

```bash
# Feature commits
git commit -m "feat(challenges): add dynamic difficulty adjustment"
git commit -m "feat(ui): implement dark mode support"
git commit -m "feat(gamification): add streak tracking system"

# Bug fix commits
git commit -m "fix(editor): resolve syntax highlighting crash on large files"
git commit -m "fix(validation): handle empty test case inputs correctly"

# Documentation commits
git commit -m "docs(readme): update installation instructions"
git commit -m "docs(api): add code examples for challenge creation"

# Refactoring commits
git commit -m "refactor(network): extract API client to separate module"
git commit -m "refactor(ui): migrate challenge list to SwiftUI"

# Test commits
git commit -m "test(challenges): add unit tests for difficulty calculation"
git commit -m "test(ui): add integration tests for user flow"

# Breaking changes
git commit -m "feat(api)!: change challenge response format

BREAKING CHANGE: Challenge API now returns difficulty as enum instead of integer.
Update client code to handle DifficultyLevel.whiteBelt instead of 1."
```

### Commit Message Best Practices

**DO:**
- Keep the subject line under 50 characters
- Use imperative mood ("add", not "added" or "adds")
- Capitalize the first letter of the description
- Include scope when relevant
- Use body to explain "what" and "why", not "how"
- Reference issues and pull requests when applicable

**DON'T:**
- End subject line with a period
- Use vague messages like "fix bug" or "update code"
- Include implementation details in the subject
- Mix multiple unrelated changes in one commit

## Pull Request Process

### 1. Pre-PR Checklist

Before creating a pull request, ensure:

- [ ] All tests pass locally (`fastlane test`)
- [ ] SwiftLint shows no warnings or errors
- [ ] Code follows project style guidelines
- [ ] Feature is complete and ready for review
- [ ] Branch is up to date with main
- [ ] Commit messages follow conventions

### 2. PR Description Template

```markdown
## Description
Brief description of changes and motivation behind them.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Related Issues
Closes #123
Related to #456

## Testing
- [ ] Unit tests added/updated and passing
- [ ] UI tests added/updated and passing
- [ ] Manual testing completed on:
  - [ ] iPhone (iOS 17+)
  - [ ] iPad (iPadOS 17+)
  - [ ] Different screen sizes

## Screenshots
<!-- Include before/after screenshots for UI changes -->

## Additional Notes
Any additional information that reviewers should know.

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### 3. Review Process

1. **Automated Checks**: Must pass before human review
   - CI/CD pipeline tests
   - SwiftLint code quality checks
   - Build validation on multiple Xcode versions

2. **Peer Review**: At least one approval required from team member
   - Code quality and architecture review
   - Testing coverage validation
   - UI/UX consistency check

3. **Maintainer Approval**: Final approval from project maintainer
   - Architecture alignment verification
   - Breaking change assessment
   - Documentation completeness

### 4. Merge Strategies

**Squash and Merge (Preferred)**
- Combines all commits into a single commit
- Keeps main branch history clean
- Use for feature branches with multiple commits

```bash
# Result: Single commit with PR title as commit message
feat(challenges): Add algorithm category support (#123)
```

**Rebase and Merge**
- Maintains individual commit history
- Use when commits are well-structured and atomic
- Preserves detailed development history

**Merge Commit**
- Creates explicit merge commit
- Use for long-running feature branches
- Preserves branch context

## Branch Protection Rules

### Main Branch Protection

```yaml
# GitHub branch protection settings
branch_protection:
  main:
    required_status_checks:
      strict: true
      contexts:
        - "ci/tests"
        - "ci/swiftlint"
        - "ci/build"
        - "ci/ui-tests"
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
      restrictions:
        users: []
        teams: ["ios-team"]
    allow_force_pushes: false
    allow_deletions: false
```

### CODEOWNERS File

```bash
# .github/CODEOWNERS
# Global code owners
* @lead-developer @senior-ios-dev

# Specific areas
/src/Models/ @backend-team @lead-developer
/src/Views/ @ui-ux-team @senior-ios-dev
/fastlane/ @devops-team @lead-developer
/.github/ @devops-team
/docs/ @technical-writer @lead-developer

# Critical files require additional review
/src/Security/ @security-team @lead-developer
/src/Networking/ @backend-team @security-team
```

## Release Workflow

### 1. Release Branch Creation

```bash
# Create release branch from main
git checkout main
git pull origin main
git checkout -b release/v2.1.0
git push -u origin release/v2.1.0
```

### 2. Release Preparation

```bash
# Update version numbers
fastlane bump_version type:minor

# Update changelog
# Edit CHANGELOG.md with release notes

# Commit version changes
git add -A
git commit -m "chore(release): bump version to 2.1.0"
git push origin release/v2.1.0
```

### 3. Release Testing

```bash
# Run comprehensive test suite
fastlane test

# Build release candidate
fastlane build_for_testing

# Deploy to TestFlight for final testing
fastlane beta
```

### 4. Release Finalization

```bash
# Merge release branch to main
gh pr create --base main --head release/v2.1.0 \
             --title "Release v2.1.0" \
             --body "Production release v2.1.0"

# After PR approval and merge, tag the release
git checkout main
git pull origin main
git tag -a v2.1.0 -m "Release version 2.1.0"
git push origin v2.1.0

# Delete release branch
git branch -d release/v2.1.0
git push origin --delete release/v2.1.0
```

## Hotfix Workflow

### Critical Production Issues

```bash
# Create hotfix branch from main
git checkout