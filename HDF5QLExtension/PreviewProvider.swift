import Cocoa
import Quartz
import HDF5Kit
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        let metadata = extractHDF5Metadata(from: fileURL) ?? "Could not read metadata"

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

        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        icon.size = NSSize(width: 64, height: 64)
        guard let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "HDF5QL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get icon"])
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let iconData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "HDF5QL", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not encode icon"])
        }
        let iconBase64 = iconData.base64EncodedString()
        let iconHTML = "<img src='data:image/png;base64,\(iconBase64)' width='64' height='64' alt='' />"
        let escapedFileName = escapeHTML(fileName)
        let escapedCreated = escapeHTML(createdStr)
        let escapedModified = escapeHTML(modifiedStr)
        let escapedReadableSize = escapeHTML(readableSize)
        let escapedMetadata = escapeHTML(metadata)

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <meta charset="utf-8" />
            <style>
                :root {
                    color-scheme: light dark;
                    --page-bg: rgba(242, 242, 247, 0.88);
                    --panel-bg: rgba(255, 255, 255, 0.76);
                    --panel-border: rgba(60, 60, 67, 0.16);
                    --primary-text: rgba(28, 28, 30, 0.96);
                    --secondary-text: rgba(60, 60, 67, 0.72);
                    --hairline: rgba(60, 60, 67, 0.12);
                }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --page-bg: rgba(28, 28, 30, 0.9);
                        --panel-bg: rgba(44, 44, 46, 0.82);
                        --panel-border: rgba(255, 255, 255, 0.1);
                        --primary-text: rgba(255, 255, 255, 0.96);
                        --secondary-text: rgba(235, 235, 245, 0.6);
                        --hairline: rgba(255, 255, 255, 0.08);
                    }
                }

                html, body {
                    margin: 0;
                    padding: 0;
                    background: var(--page-bg);
                    font-family: -apple-system, system-ui, sans-serif;
                    color: var(--primary-text);
                    height: 100%;
                }

                .container {
                    height: 100%;
                    box-sizing: border-box;
                    padding: 18px;
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                    min-height: 0;
                }

                .header {
                    display: flex;
                    align-items: center;
                    gap: 14px;
                    padding-bottom: 12px;
                    border-bottom: 1px solid var(--hairline);
                    flex: 0 0 auto;
                }

                .icon {
                    width: 60px;
                    height: 60px;
                    flex: 0 0 60px;
                }

                .title {
                    min-width: 0;
                }

                .title h1 {
                    margin: 0;
                    font-size: 19px;
                    font-weight: 600;
                    line-height: 1.25;
                    letter-spacing: -0.02em;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    white-space: nowrap;
                }

                .subtitle {
                    margin-top: 4px;
                    font-size: 12px;
                    color: var(--secondary-text);
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }

                .summary-card {
                    flex: 0 0 auto;
                    background: var(--panel-bg);
                    border: 1px solid var(--panel-border);
                    border-radius: 12px;
                    padding: 10px 12px;
                    backdrop-filter: blur(18px);
                    -webkit-backdrop-filter: blur(18px);
                }

                .summary-grid {
                    display: grid;
                    grid-template-columns: auto minmax(0, 1fr) auto minmax(0, 1fr) auto minmax(0, 1fr);
                    gap: 12px;
                    align-items: baseline;
                }

                .summary-item {
                    min-width: 0;
                    display: contents;
                }

                .summary-label {
                    font-size: 10px;
                    font-weight: 600;
                    letter-spacing: 0.03em;
                    text-transform: uppercase;
                    color: var(--secondary-text);
                    margin: 0;
                    white-space: nowrap;
                }

                .summary-value {
                    font-size: 12px;
                    line-height: 1.25;
                    color: var(--primary-text);
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }

                .metadata-panel {
                    flex: 1;
                    min-height: 0;
                    background: var(--panel-bg);
                    border: 1px solid var(--panel-border);
                    border-radius: 14px;
                    overflow: hidden;
                    backdrop-filter: blur(18px);
                    -webkit-backdrop-filter: blur(18px);
                }

                .metadata-header {
                    padding: 8px 12px;
                    font-size: 11px;
                    font-weight: 600;
                    color: var(--secondary-text);
                    border-bottom: 1px solid var(--hairline);
                }

                .metadata {
                    white-space: pre-wrap;
                    word-break: break-word;
                    overflow-y: scroll;
                    overflow-x: hidden;
                    padding: 12px;
                    margin: 0;
                    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                    font-size: 12px;
                    line-height: 1.5;
                    color: var(--primary-text);
                    height: 100%;
                    box-sizing: border-box;
                    scrollbar-gutter: stable;
                }

                .metadata::-webkit-scrollbar {
                    width: 10px;
                }

                .metadata::-webkit-scrollbar-thumb {
                    background: rgba(128, 128, 128, 0.45);
                    border-radius: 999px;
                    border: 2px solid transparent;
                    background-clip: content-box;
                }

                .metadata::-webkit-scrollbar-track {
                    background: transparent;
                }

            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="icon">\(iconHTML)</div>
                    <div class="title">
                        <h1>\(escapedFileName)</h1>
                        <div class="subtitle">HDF5 dataset preview</div>
                    </div>
                </div>
                <div class="summary-card">
                    <div class="summary-grid">
                        <div class="summary-item">
                            <div class="summary-label">Size</div>
                            <div class="summary-value">\(escapedReadableSize)</div>
                        </div>
                        <div class="summary-item">
                            <div class="summary-label">Created</div>
                            <div class="summary-value">\(escapedCreated)</div>
                        </div>
                        <div class="summary-item">
                            <div class="summary-label">Modified</div>
                            <div class="summary-value">\(escapedModified)</div>
                        </div>
                    </div>
                </div>
                <div class="metadata-panel">
                    <div class="metadata-header">Contents</div>
                    <pre class="metadata">\(escapedMetadata)</pre>
                </div>
            </div>
        </body>
        </html>
        """

        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 700, height: 400)) { _ in
            return html.data(using: .utf8)!
        }
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
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
