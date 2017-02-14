//
//  ResourceManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate struct BookData
{
	let book: Book
	let binding: ParagraphBinding
	let datasource: TranslationTableViewDS
}

fileprivate struct NotesData
{
	let resource: ResourceCollection
	let datasource: NotesTableDS
}

// This class handles the functions concerning the resource table
class ResourceManager: TranslationParagraphListener, TableCellSelectionListener
{
	// ATTRIBUTES	-----------
	
	private weak var resourceTableView: UITableView!
	private weak var addNotesDelegate: AddNotesDelegate!
	
	private var sourceBooks = [BookData]()
	private var notes = [NotesData]()
	
	private var currentLiveResource: LiveResource?
	private var currentResourceIndex: Int?
	
	
	// COMPUTED PROPERTIES	---
	
	let targetedCellIds = [NotesCell.identifier, ThreadCell.identifier, PostCell.identifier]
	
	var resourceTitles: [String]
	{
		return sourceBooks.map { $0.book.identifier } + notes.map { $0.resource.name }
	}
	
	// Currently selected book data, if one is selected
	private var currentSourceBookData: BookData?
	{
		if let currentResourceIndex = currentResourceIndex, currentResourceIndex < sourceBooks.count
		{
			return sourceBooks[currentResourceIndex]
		}
		else
		{
			return nil
		}
	}
	
	// Currently selected notes data, if one is selected
	private var currentNotesData: NotesData?
	{
		if let currentResourceIndex = currentResourceIndex, currentResourceIndex >= sourceBooks.count
		{
			return notes[currentResourceIndex - sourceBooks.count]
		}
		else
		{
			return nil
		}
	}
	
	
	// INIT	-------------------
	
	init(resourceTableView: UITableView, addNotesDelegate: AddNotesDelegate)
	{
		self.resourceTableView = resourceTableView
		self.addNotesDelegate = addNotesDelegate
	}
	
	
	// IMPLEMENTED METHODS	---
	
	// This method should be called whenever the paragraph data on the translation side is updated
	// Makes sure right notes resources are displayed
	func translationParagraphsUpdated(_ paragraphs: [Paragraph])
	{
		for noteData in notes
		{
			noteData.datasource.translationParagraphsUpdated(paragraphs)
		}
	}
	
	func onTableCellSelected(_ cell: UITableViewCell, identifier: String)
	{
		// When a paragraph-notes -cell is selected, adds a new thread
		if identifier == NotesCell.identifier, let cell = cell as? NotesCell
		{
			let chapterIndex = cell.note.chapterIndex
			let pathId = cell.note.pathId
			
			// Finds the associated paragraphs from the resource data
			var associatedParagraphData = [(String, Paragraph)]()
			
			do
			{
				for bookData in sourceBooks
				{
					let sourcePathIds = bookData.binding.sourcesForTarget(pathId)
					
					if !sourcePathIds.isEmpty, let languageName = try Language.get(bookData.book.languageId)?.name
					{
						for i in 0 ..< sourcePathIds.count
						{
							if let paragraphId = try ParagraphHistoryView.instance.mostRecentId(bookId: bookData.book.idString, chapterIndex: chapterIndex, pathId: sourcePathIds[i]), let paragraph = try Paragraph.get(paragraphId)
							{
								let title = languageName + (sourcePathIds.count == 1 ? ":" : " (\(i + 1)):")
								associatedParagraphData.append((title, paragraph))
							}
							else
							{
								print("ERROR: Failed to find the latest version of associated paragraph in \(languageName) with path: \(sourcePathIds[i])")
							}
						}
					}
				}
			}
			catch
			{
				print("ERROR: Failed to prepare associated paragraph data. \(error)")
			}
			
			addNotesDelegate.insertThread(noteId: cell.note.idString, pathId: cell.note.pathId, associatedParagraphData: associatedParagraphData)
		}
		// When a thread cell is selected, hides / shows the thread contents
		else if identifier == ThreadCell.identifier, let cell = cell as? ThreadCell
		{
			currentNotesData?.datasource.changeThreadVisibility(thread: cell.thread)
		}
		// When a post is tapped, creates a response to that post
		else if identifier == PostCell.identifier, let cell = cell as? PostCell
		{
			addNotesDelegate.insertPost(threadId: cell.post.threadId)
		}
	}
	
	
	// OTHER METHODS	-------
	
	func setResources(sourceBooks: [(Book, ParagraphBinding)], notes: [ResourceCollection])
	{
		// TODO: Deactivate old resources if they are not present anymore
		
		self.sourceBooks = sourceBooks.map
		{
			book, binding in
			
			return BookData(book: book, binding: binding, datasource: TranslationTableViewDS(tableView: resourceTableView!, cellReuseId: "sourceCell", bookId: book.idString))
		}
		
		self.notes = notes.map { NotesData(resource: $0, datasource: NotesTableDS(tableView: resourceTableView!, resourceCollectionId: $0.idString)) }
		
		selectResource(atIndex: 0)
	}
	
	func indexPathsForTargetPathId(_ targetPathId: String) -> [IndexPath]
	{
		// Uses bindings to find source index paths from book data
		if let currentSourceBookData = currentSourceBookData
		{
			return currentSourceBookData.binding.sourcesForTarget(targetPathId).flatMap { currentSourceBookData.datasource.indexForPath($0) }
		}
		// Notes table data sources keep track of path indices
		else if let currentNotesData = currentNotesData
		{
			return currentNotesData.datasource.indexesForPath(targetPathId)
		}
		else
		{
			return []
		}
	}
	
	func targetPathsForSourcePath(_ sourcePathId: String) -> [String]
	{
		// In source translation data, bindings are used for path to path connections
		if let currentSourceBookData = currentSourceBookData
		{
			return currentSourceBookData.binding.targetsForSource(sourcePathId)
		}
		// Other data is already using the same path ids
		else
		{
			return [sourcePathId]
		}
	}
	
	func selectResource(atIndex index: Int)
	{
		guard index != currentResourceIndex else
		{
			return
		}
		
		guard index >= 0 && index < sourceBooks.count + notes.count else
		{
			print("ERROR: Trying to activate a resource at non-existing index")
			return
		}
		
		// Stops the listening for the current resource
		currentLiveResource?.pause()
		
		// Finds the new resource and activates it
		if index < sourceBooks.count
		{
			let datasource = sourceBooks[index].datasource
			currentLiveResource = datasource
			resourceTableView.dataSource = datasource
		}
		else
		{
			let datasource = notes[index - sourceBooks.count].datasource
			currentLiveResource = datasource
			resourceTableView.dataSource = datasource
		}
		
		currentResourceIndex = index
		currentLiveResource?.activate()
		
		resourceTableView.reloadData()
	}
	
	func pause()
	{
		currentLiveResource?.pause()
	}
	
	func activate()
	{
		currentLiveResource?.activate()
	}
}
