//
//  TextElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Text elements are used in construction of a paragraph's text data
// This is a common protocol for all elements that want to be used to store text data in a paragraph
// Text elements should not contain verses but be stored under them instead
protocol ParaContent: AttributedStringConvertible, USXConvertible, JSONConvertible
{
	// A simple text representation of the element
	var text: String { get }
}
