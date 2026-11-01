# PyStream iOS Client

Native SwiftUI wrapper for the PyStream Windows-hosted WebRTC
remote desktop client.

## Development

This repository is designed to be edited and pushed from Windows.

GitHub Actions uses a hosted macOS runner to generate the Xcode
project and compile the iOS Simulator application.

No local Mac or Xcode installation is required.

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── build-ios.yml
├── ios/
│   └── LANRemote/
│       ├── LANRemoteApp.swift
│       ├── ContentView.swift
│       └── RemoteWebView.swift
├── .gitignore
├── README.md
└── project.yml