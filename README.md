[![Swift](https://github.com/hacknus/HDF5QL/actions/workflows/swift.yml/badge.svg)](https://github.com/hacknus/HDF5QL/actions/workflows/swift.yml)

# A HDF5 QuickLook Plugin for macOS Finder

This is a simple Quicklook plugin for macOS Finder to preview the structure of HDF5 files. This works with extensions `.h5` and `.hdf5`.

![screenshot](screenshot.png)

It requires that `hdf5` is installed: 
```shell
brew install hdf5
```

## Installation

Pre-compiled binaries are provided for Apple Silicon (Arm64) here: [Releases](https://github.com/hacknus/HDF5QL/releases)

To install, you need to place the main app `HDF5QL.app` in the `Applications` folder and launch it once. This should register the plugin with the operating system and it should work.
The main app needs to remain in the `Applications` folder.

If it does not work, try running this:
```shell
qlmanage -r cache
qlmanage -r
killall -9 Finder
killall -9 mdworker_shared
```
