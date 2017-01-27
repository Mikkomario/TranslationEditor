//
//  UIUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension UIButton
{
	// Adjusts the button's color theme
	func setVisualTheme(_ theme: Theme)
	{
		backgroundColor = theme.colour
		
		titleLabel?.textColor = theme.textColour
		tintColor = theme.textColour
		setTitleColor(theme.textColour, for: .normal)
		setTitleColor(theme.textColour, for: .disabled)
	}
}