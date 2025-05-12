//
//  PreviewProvider.swift
//  HDF5QLExtension
//
//  Created by Linus Stöckli on 19.02.2025.
//

import Cocoa
import Quartz
import HDF5Kit // Import the wrapper

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    
    
    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:
     
     - Modify the extension's Info.plist by setting
     <key>QLIsDataBasedPreview</key>
     <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.
     
     - Change the NSExtensionPrincipalClass to this class.
     e.g.
     <key>NSExtensionPrincipalClass</key>
     <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        
        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
        //To return Data of a supported content type:
        
        let contentType = UTType.plainText // replace with your data type
        
        let reply = QLPreviewReply.init(dataOfContentType: contentType, contentSize: CGSize.init(width: 800, height: 800)) { (replyToUpdate : QLPreviewReply) in
            let fileURL = request.fileURL // ✅ Extract file URL from the request
            
            //let data = Data("Hello world".utf8)
            
            // Extract HDF5 metadata
            let metadata = self.extractHDF5Metadata(from: fileURL) ?? "Could not read metadata"
            
            //let data = metadata.data(using: .utf8)!
            let data = Data(metadata.utf8)
            
            //setting the stringEncoding for text and html data is optional and defaults to String.Encoding.utf8
            replyToUpdate.stringEncoding = .utf8
            
            //initialize your data here
            
            return data
        }
        
        return reply
    }
    
    private func extractHDF5Metadata(from fileURL: URL) -> String? {
        guard let file = File.open(fileURL.path, mode: .readOnly) else {
            fatalError("Failed to open \(fileURL.path)")
        }
        
        var metadata = "HDF5 File Metadata:\n"
        
        // Extract groups
        let groups = file.getGroupNames() ?? ["<no groups>"]
        metadata += "Groups: \(groups)\n"
        for groupName in groups {
            metadata += "Group: \(groupName)\n"
            if let group = file.openGroup(groupName) {
                metadata += "Name: \(group.name)\n"
                metadata += "Id: \(group.id)\n"
                metadata += "Object Names: \(group.objectNames())\n"
                metadata += "Attr Names: \(group.attributeNames())\n"
                metadata += "Dataset Names: \(group.datasetNames())\n"
                
                let attributeNames = group.attributeNames()
                for attributeName in attributeNames {
                    if let attribute = group.openDoubleAttribute(attributeName) {
                        do {
                            let value = try attribute.read()
                            metadata += "    >> \(attributeName) : \(value)\n"
                        } catch {
                            if let attribute = group.openStringAttribute(attributeName) {
                                do {
                                    let value = try attribute.read()
                                    metadata += "    >> \(attributeName) : \(value)\n"
                                } catch {
                                    metadata += "    >> \(attributeName) : <error reading>\n"
                                }
                            }
                        }
                    } else {
                        metadata += "  >> \(attributeName): <unreadable>\n"
                    }
                }
            } else {
                metadata += "  >> Failed to open group.\n"
            }
        }
        
        return metadata
    }
}
