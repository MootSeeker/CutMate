# Contributing to CutMate

First off, thank you for considering contributing to CutMate! It's people like you that will help make this weight-loss app successful.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## Code of Conduct

This project and everyone participating in it is governed by the CutMate [Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project team.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

**Before Submitting A Bug Report:**

* Check the documentation for tips on addressing the issue yourself.
* Perform a cursory search to see if the problem has already been reported.

**How Do I Submit A (Good) Bug Report?**

Bugs are tracked as GitHub issues. Create an issue and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps to reproduce the problem** in as much detail as possible.
* **Provide specific examples to demonstrate the steps**.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots or animated GIFs** if applicable.
* **If the problem is related to performance or memory**, include a performance profile capture if possible.
* **If the problem occurs on a specific device/OS**, include device name, OS version, and app version.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

**Before Submitting An Enhancement Suggestion:**

* Check if the enhancement has already been suggested.
* Check if the functionality exists in a recent release.

**How Do I Submit A (Good) Enhancement Suggestion?**

Enhancement suggestions are tracked as GitHub issues. Create an issue and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as much detail as possible.
* **Provide specific examples to demonstrate the steps** if applicable.
* **Describe the current behavior and explain which behavior you expected to see instead** and why.
* **Include screenshots or animated GIFs** if applicable.
* **Explain why this enhancement would be useful** to most CutMate users.
* **List some other applications where this enhancement exists**, if applicable.

### Pull Requests

* Fill in the required pull request template
* Do not include issue numbers in the PR title
* Include screenshots and animated GIFs in your pull request whenever possible
* Follow the Flutter style guide
* Include unit tests when adding new features
* End all files with a newline
* Avoid platform-dependent code

## Development Process

### Setting Up Your Development Environment

1. Install Flutter by following the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).
2. Clone the repository: 
```powershell
git clone https://github.com/yourusername/cutmate.git
```
3. Install dependencies: 
```powershell
flutter pub get
```
4. Run the app: 
```powershell
flutter run
```

### Flutter Style Guide

* Follow the [Effective Dart: Style Guide](https://dart.dev/guides/language/effective-dart/style)
* Use clear, meaningful variable and method names
* Document public APIs with dartdoc comments
* Keep methods small and focused on a single responsibility
* Use the Flutter linter rules defined in analysis_options.yaml

### Git Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

#### Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

### Testing Guidelines

* Write unit tests for new code
* Write integration tests for new features
* Ensure all tests pass before submitting a pull request
* Aim for high test coverage

### Documentation Guidelines

* Update the README.md with details of changes to the interface
* Update the docs directory with any new information
* Comment your code where necessary
* Generate and update API documentation for all public APIs

## App-Specific Contribution Notes

### User Data Privacy

* Never commit real user data, even in tests
* Be mindful of how you handle and store user data
* Follow GDPR and other privacy regulations

### AI and Machine Learning

* Document AI usage clearly
* Consider the performance impact of ML features
* Include fallback options for when AI services are unavailable

### UI/UX Considerations

* Follow Material Design guidelines for Android
* Follow Human Interface Guidelines for iOS
* Ensure accessibility features are maintained
* Consider the psychological impact of weight-loss messaging

## Additional Notes

### Issue and Pull Request Labels

| Label name | Description |
| --- | --- |
| `bug` | Confirmed bugs or reports likely to be bugs |
| `enhancement` | Feature requests |
| `documentation` | Documentation-related contributions |
| `good-first-issue` | Good for newcomers |
| `help-wanted` | Extra attention is needed |

## Attribution

This Contributing Guide is adapted from the open-source contribution guidelines templates and best practices.

Last updated: May 27, 2025
