# ExtraBuildPhase
[![MIT Lincese](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

ExtraBuildPhase is a plugin for Xcode that created for running [SwiftLint](https://github.com/realm/SwiftLint), but is customizable by shell script.

## Requirements
- Xcode 7.1 or later
- [SwiftLint](https://github.com/realm/SwiftLint) for default shell script

## Installation

Xcode Plug-ins Locations are following:
- Local System: `/Library/Application Support/Developer/Shared/Xcode/Plug-ins`
- User Home: `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`

### Using Installers
- [Homebrew-Cask](http://caskroom.io) (*User Home*): `brew cask install extrabuildphase`  
- [Alcatraz](http://alcatraz.io) (*User Home*)
- Installer package (Local System): [ExtraBuildPhase-0.3.1.pkg](https://github.com/norio-nomura/ExtraBuildPhase/releases/download/0.3.1/ExtraBuildPhase-0.3.1.pkg)

*Plugin location installed by Homebrew-Cask has been changed from Local System to User Home. If you have installed 0.3 or earlier by Homebrew-Cask, Please remove `ExtraBuildPhase.xcplugin` manually from Local System.*

### Manual Install
1. Download [ExtraBuildPhase.xcplugin-0.3.1.zip](https://github.com/norio-nomura/ExtraBuildPhase/releases/download/0.3.1/ExtraBuildPhase.xcplugin-0.3.1.zip)
2. Unzip it
3. Copy `ExtraBuildPhase.xcplugin` to one of Xcode Plug-ins Location

### Build By Yourself
1. Building the project by Xcode will install the plugin. (to User Home)

Restart Xcode after installing

## Configuration
```sh
# Change shell script
defaults write io.github.norio-nomura.ExtraBuildPhase shellScript -string '
if which swiftlint >/dev/null; then
    swiftlint lint --use-script-input-files --config ~/.swiftlint.yml 2>/dev/null
fi
exit 0 # ignore result of swiftlint
'
# Changes will be applied after "Product > Clean⇧⌘K"

# Show environment variables in build log
defaults write io.github.norio-nomura.ExtraBuildPhase showEnvVarsInLog -bool true

# Run shell script not only on Xcode, but also xcodebuild.
defaults write io.github.norio-nomura.ExtraBuildPhase isNotLimitedToXcode -bool true
```

## Author

Norio Nomura

## License

ExtraBuildPhase is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
