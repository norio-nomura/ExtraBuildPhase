# ExtraBuildPhase
[![MIT Lincese](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

ExtraBuildPhase is a plugin for Xcode that created for running [SwiftLint](https://github.com/realm/SwiftLint), but is customizable by shell script.

## Requirements
- Xcode 7.1 or later
- [SwiftLint](https://github.com/realm/SwiftLint) for default shell script

## Installation
1. Build the Xcode project
2. Restart Xcode

## Configuration
```sh
# Change shell script
defaults write io.github.norio-nomura.ExtraBuildPhase shellScript -string '
if which swiftlint >/dev/null; then
    swiftlint 2>/dev/null
fi
exit 0 # ignore result of swiftlint
'
# Changes will be applied after "Product > Clean⇧⌘K"

# Show environment variables in build log
defaults write io.github.norio-nomura.ExtraBuildPhase showEnvVarsInLog -bool true
```

## Author

Norio Nomura

## License

ExtraBuildPhase is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
