//
//  ShareViewController.swift
//  ShareExample
//

import UIKit
import MobileCoreServices
import AVFoundation

struct LoadImportedContentCommand {
    
    struct LoadedFile {
        let title: String
        let `extension`: String
        let data: Data
    }
    
    let attachment: NSItemProvider
    
    private func nameAndExtension(from fullName: String) -> (title: String, extension: String) {
        guard let lastDotIndex = fullName.lastIndex(of: ".") else {
            return (title: "Unknown", extension: "Unknown")
        }
        let title = fullName.prefix(upTo: lastDotIndex)
        let `extension` = fullName.suffix(from: fullName.index(lastDotIndex, offsetBy: 1))
        return (title: String(title), extension: String(`extension`))
    }
    
    func loadFile() async throws -> LoadedFile {
        let item = try await attachment.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil)
        guard let itemUrl = item as? URL else {
            fatalError()
        }
        let (title, `extension`) = nameAndExtension(from: itemUrl.lastPathComponent)
        let data = try Data(contentsOf: itemUrl)
        return LoadedFile(title: title, extension: `extension`, data: data)
    }
    
}

@objc(ShareViewController)
class ShareViewController: UIViewController {

    private let titleLabel = UILabel()
    private let previewsTable = UITableView()
    private let confirmButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        getFilesExtensionContext()
    }

    func getFilesExtensionContext() {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem],
              inputItems.count > 0
        else {
            close()
            return
        }

        inputItems.forEach { item in
            if let attachments = item.attachments,
               !attachments.isEmpty {
                attachments.forEach { attachment in
                    Task {
                        let file = try? await LoadImportedContentCommand(attachment: attachment).loadFile()
                        print(file)
                    }
                }
            }
        }
    }
    
    func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

}
