//
//  ViewController.swift
//  LDrawPartPackager
//
//  Created by Shane Whitehead on 3/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

	@IBOutlet var logTextView: NSTextView!
	@IBOutlet weak var zipTargetPath: NSTextField!
	@IBOutlet weak var ldrawSourcePath: NSTextField!
	
	@IBOutlet weak var browseTarget: NSButton!
	@IBOutlet weak var browseSource: NSButton!
	@IBOutlet weak var packIt: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		let home = FileManager.default.homeDirectoryForCurrentUser
//		let target = home.appendingPathComponent("LDrawParts.zip")
//
//		let path = URL(fileURLWithPath: "/Users/swhitehead/Downloads/ldraw")
//		Packager.shared.pack(source: path, into: target)
		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	func everything(enabled: Bool) {
		zipTargetPath.isEnabled = enabled
		ldrawSourcePath.isEnabled = enabled
		
		browseSource.isEnabled = enabled
		browseTarget.isEnabled = enabled
		packIt.isEnabled = enabled
	}
	
	func selectDirectory(titled: String) -> URL? {
		let openPanel = NSOpenPanel()
		openPanel.title = titled
		openPanel.showsResizeIndicator = true
		openPanel.showsHiddenFiles = true
		openPanel.canChooseFiles = false
		openPanel.canChooseDirectories = true
		openPanel.canCreateDirectories = false
		openPanel.allowsMultipleSelection = false
		
		if openPanel.runModal() == .OK {
			guard openPanel.urls.count > 0 else {
				return nil
			}
			let path = openPanel.urls[0]
			return path
		}
		return nil
	}

	@IBAction func sourcePathTapped(_ sender: Any) {
		guard let path = selectDirectory(titled: "LDraw Parts Source") else {
			return
		}
		self.ldrawSourcePath.stringValue = path.path
	}
	
	@IBAction func targetPathTapped(_ sender: Any) {
		guard let path = selectDirectory(titled: "Package Destination") else {
			return
		}
		self.zipTargetPath.stringValue = path.path
	}
	
	@IBAction func packItTapped(_ sender: Any) {
		everything(enabled: false)
		let sourceValue = ldrawSourcePath.stringValue
		let destValue = zipTargetPath.stringValue
		guard sourceValue.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
			return
		}
		guard destValue.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
			return
		}
		let sourcePath = URL(fileURLWithPath: sourceValue, isDirectory: true)
		let destPath = URL(fileURLWithPath: destValue, isDirectory: true)
		let target = destPath.appendingPathComponent("LDrawParts.zip")
		
		do {
			if FileManager.default.fileExists(atPath: target.path) {
				try FileManager.default.removeItem(at: target)
			}
			
			DispatchQueue.global().async {
				do {
					try Packager.shared.pack(source: sourcePath, into: target, notifier: self)
				} catch let error {
					print(error)
					DispatchQueue.main.async {
						self.everything(enabled: true)
						self.show(alert: "Could not package ZIP to \(target): \(error)")
					}
				}
			}
		} catch let error {
			everything(enabled: true)
			print(error);
			show(alert: "Could not remove ZIP package from \(target): \(error)")
		}
		
//		let path = URL(fileURLWithPath: "/Users/swhitehead/Downloads/ldraw")
	}
	
	func show(alert text: String) {
		let alert = NSAlert()
		alert.addButton(withTitle: "OK")
		alert.messageText = text
		alert.runModal()
	}
}

extension ViewController: PackageNotifier {
	
	func packCompleted() {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.packCompleted()
			}
			return
		}
		everything(enabled: true)
	}
	
	func packed(file: String) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.packed(file: file)
			}
			return
		}
		
		logTextView.textStorage?.append(NSAttributedString(string: file + "\n"))
		logTextView.scrollToEndOfDocument(self)
	}
}
