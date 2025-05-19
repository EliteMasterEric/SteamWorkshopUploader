# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-05-18

### Added
- Added a "Formatting Help" button to the Description editor.
- Links in the Description editor can now be clicked.

### Changed
- Error codes in the log are now more readable

### Fixed
- Fixed an issue where the description wasn't being uploaded when submitting.
- Fixed an issue where the "Quit" and "Clear User Preferences" menu options would do nothing when clicked.
- Fixed an issue where the "Back" button would do nothing when clicked.

### Removed
- Hid the "UGC Item Type" dropdown since it isn't useful for most games, may re-enable under an "Advanced Options" in the future.


## [1.0.0] - 2025-05-11

Initial release.

### Added
- Added ability to create UGC items for listed games.
- Added ability to retrieve current user's UGC items for listed games.
- Added ability to edit and upload workshop metadata for UGC.
- Added ability to upload preview thumbnails for UGC (with support for static and animated images).
- Added ability to upload content for UGC from a selected folder.
- Added ability to exclude certain files from a UGC upload.
- Added ability to exclude files automatically via a .steamignore file.

