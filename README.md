# ExtraBuildPhase
[![MIT Lincese](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

ExtraBuildPhase is a plugin for Xcode that created for running [SwiftLint](https://github.com/realm/SwiftLint), but is customizable by shell script.

## Requirements
- Xcode 7.1 or later
- [SwiftLint](https://github.com/realm/SwiftLint) for default shell script

## Installation

### Use Homebrew-Cask
1. Install [Homebrew-Cask](http://caskroom.io)
2. run `brew cask install extrabuildphase` on CLI
3. Restart Xcode

*This method installs the plug-in at `/Library/Application Support/Developer/Shared/Xcode/Plug-ins`*

### Use pre-built plugin
1. Download [ExtraBuildPhase.xcplugin-0.2.zip](https://github.com/norio-nomura/ExtraBuildPhase/releases/download/0.2/ExtraBuildPhase.xcplugin-0.2.zip)
2. Unzip it
3. Move `ExtraBuildPhase.xcplugin` to `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`
4. Restart Xcode

### Build by yourself
1. Build the Xcode project
2. Restart Xcode

*This method installs the plug-in at `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`*

## Configuration
```sh
# Change shell script
defaults write io.github.norio-nomura.ExtraBuildPhase shellScript -string '
if which swiftlint >/dev/null; then
    swiftlint lint --config ~/.swiftlint.yml 2>/dev/null
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
