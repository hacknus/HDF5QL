import Cocoa
import Quartz
import HDF5Kit
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        let metadata = extractHDF5Metadata(from: fileURL) ?? "Could not read metadata"

        // Fetch file attributes
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileName = fileURL.lastPathComponent
        let fileSize = (fileAttributes[.size] as? NSNumber)?.int64Value ?? 0
        let fileCreationDate = fileAttributes[.creationDate] as? Date
        let fileModificationDate = fileAttributes[.modificationDate] as? Date

        let byteFormatter = ByteCountFormatter()
        byteFormatter.countStyle = .file
        let readableSize = byteFormatter.string(fromByteCount: fileSize)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let createdStr = fileCreationDate.map { dateFormatter.string(from: $0) } ?? "Unknown"
        let modifiedStr = fileModificationDate.map { dateFormatter.string(from: $0) } ?? "Unknown"

        // Get icon
        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        icon.size = NSSize(width: 256, height: 256)
        guard let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "HDF5QL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get icon"])
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let iconData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "HDF5QL", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not encode icon"])
        }
        let iconBase64 = iconData.base64EncodedString()
        let iconHTML = "<img src='data:image/png;base64,\(iconBase64)' width='256' height='256' />"

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8" />
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                    font-family: -apple-system, system-ui, sans-serif;
                    font-size: 13px;
                    color: black;
                    height: 100%;
                }
                .container {
                    display: flex;
                    flex-direction: row;
                    height: 100%;
                    box-sizing: border-box;
                    padding: 16px;
                }
                .icon {
                    flex: 0 0 256px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .content {
                    flex: 1;
                    padding-left: 24px;
                    display: flex;
                    flex-direction: column;
                    justify-content: flex-start;
                }
                .header {
                    margin-bottom: 16px;
                }
                .header b {
                    font-size: 16px;
                    display: block;
                    margin-bottom: 4px;
                }
                .metadata {
                    white-space: pre-wrap;
                    overflow-y: auto;
                    color: #333;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">\(iconHTML)</div>
                <div class="content">
                    <div class="header">
                        <b>\(fileName)</b>
                        Created: \(createdStr)<br/>
                        Modified: \(modifiedStr)<br/>
                        Size: \(readableSize)
                    </div>
                    <div class="metadata">\(metadata)</div>
                </div>
            </div>
        </body>
        </html>
        """

        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 700, height: 400)) { _ in
            return html.data(using: .utf8)!
        }
    }
    
    private func extractHDF5Metadata(from fileURL: URL) -> String? {
        guard let file = File.open(fileURL.path, mode: .readOnly) else {
            return nil
        }
        
        var metadata = ""
        let groups = file.getGroupNames() ?? ["<no groups>"]
        for groupName in groups {
            metadata += "📁 Group: \(groupName)\n"
            if let group = file.openGroup(groupName) {
                metadata += "  Datasets:\n"
                for dataset in group.objectNames() {
                    metadata += "    • \(dataset)\n"
                }
                
                metadata += "  Attributes:\n"
                for attributeName in group.attributeNames() {
                    if let attribute = group.openDoubleAttribute(attributeName) {
                        do {
                            let value = try attribute.read()
                            metadata += "    - \(attributeName): \(value)\n"
                        } catch {
                            if let attribute = group.openStringAttribute(attributeName) {
                                do {
                                    let value = try attribute.read()
                                    metadata += "    - \(attributeName): \(value)\n"
                                } catch {
                                    metadata += "    - \(attributeName): <error reading>\n"
                                }
                            }
                        }
                    }
                }
            } else {
                metadata += "  ⚠️ Failed to open group.\n"
            }
            metadata += "\n"
        }
        
        return metadata
    }
}
