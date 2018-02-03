//
//  Packager.swift
//  LDrawPartPackager
//
//  Created by Shane Whitehead on 3/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation
import ZIPFoundation

protocol PackageNotifier {
	func packed(file: String)
	func packCompleted()
}

class Packager {
	
	static let shared: Packager = Packager()
	
	func pack(source: URL, into target: URL, notifier: PackageNotifier) throws {
		let partsPath = source.appendingPathComponent("parts", isDirectory: true)
		let pPath = source.appendingPathComponent("p", isDirectory: true)
		let modelsPath = source.appendingPathComponent("models", isDirectory: true)
		let colorConfig = source.appendingPathComponent("LDConfig.ldr", isDirectory: false)
		
		print("Pack from \(source) to \(target)")
		
		guard let archive = Archive(url: target, accessMode: .create) else {
			throw Archive.ArchiveError.unwritableArchive
		}
		
		try add(path: partsPath, to: archive, notifier: notifier)
		try add(path: pPath, to: archive, notifier: notifier)
		try add(path: modelsPath, to: archive, notifier: notifier)
		try add(file: colorConfig, to: archive, notifier: notifier)
		
		notifier.packed(file: "")
		notifier.packed(file: "All done")
		
		notifier.packCompleted()
	}
	
	fileprivate func add(path: URL, to archive: Archive, notifier: PackageNotifier) throws {
		let fileManager: FileManager = FileManager.default
		print("Add \(path)")
		let dirEnumerator = fileManager.enumerator(atPath: path.path)
		// If the caller wants to keep the parent directory, we use the lastPathComponent of the source URL
		// as common base for all entries (similar to macOS' Archive Utility.app)
		let directoryPrefix = path.lastPathComponent
		while let entryPath = dirEnumerator?.nextObject() as? String {
			let finalPath = directoryPrefix + "/" + entryPath
			try archive.addEntry(with: finalPath, relativeTo: path.deletingLastPathComponent())
			notifier.packed(file: finalPath)
		}
		print("Done adding \(path)")
	}
	
	fileprivate func add(file: URL, to archive: Archive, notifier: PackageNotifier) throws {
		try archive.addEntry(with: file.lastPathComponent, relativeTo: file.deletingLastPathComponent())
		notifier.packed(file: file.lastPathComponent)
	}
	
}
