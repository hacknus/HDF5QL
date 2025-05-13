import SwiftUI

struct ContentView: View {
    @State private var hdf5Available: Bool = false
    @State private var showCopyMessage: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if hdf5Available {
                Image(systemName: "checkmark.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                
                Text("HDF5 is installed. HDF5 Quicklook Preview is ready!")
                    .font(.title2)
                    .bold()
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.orange)
                
                Text("HDF5 Not Found")
                    .font(.title2)
                    .bold()

                Text("To enable HDF5 support, please install it via Homebrew:")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Code snippet and Copy button in a cleaner layout
                HStack(spacing: 10) {
                    Text("brew install hdf5")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    Button(action: {
                        // Copy the brew install command to the clipboard
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString("brew install hdf5", forType: .string)
                        showCopyMessage = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .font(.body)
                            .frame(width: 30, height: 30) // Adjust the size of the icon button
                    }
                }

                if showCopyMessage {
                    Text("Command copied to clipboard!")
                        .foregroundColor(.green)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                Text("After installation, the preview should be ready!")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        }
        .padding()
        .onAppear {
            hdf5Available = Self.isHDF5Installed()
        }
    }

    /// Check if `h5dump` (part of HDF5) is available on the system
    private static func isHDF5Installed() -> Bool {
        // Specify the expected path for h5dump installed by Homebrew
        let h5dumpPath = "/opt/homebrew/bin/h5dump"
        
        // Use FileManager to check if the file exists
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: h5dumpPath)
        
        if fileExists {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    ContentView()
}
