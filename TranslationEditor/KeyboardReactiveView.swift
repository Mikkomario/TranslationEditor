//
//  KeyboardReactiveView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class KeyboardReactiveView: UIView
{
	// ATTRIBUTES	-------------
	
	private weak var mainView: UIView!
	private var _importantElements = [Weak<UIView>]()
	var importantElements: [UIView]
	{
		get
		{
			return _importantElements.flatMap { $0.value }
		}
		set
		{
			_importantElements = newValue.weakReference
		}
	}
	
	var margin: CGFloat = 16
	var topConstraint: NSLayoutConstraint?
	var bottomConstraint: NSLayoutConstraint?
	
	private var observers = [Any]()
	private var totalRaise: CGFloat = 0
	
	
	// COPUTED PROPERTIES	-----
	
	private var firstResponderElement: UIView? { return importantElements.first(where: { $0.isFirstResponder }) }
	
	
	// IMPLEMENTED METHODS	----
	
	deinit
	{
		endKeyboardListening()
	}
	
	
	// OTHER METHODS	--------
	
	func configure(mainView: UIView, elements: [UIView], topConstraint: NSLayoutConstraint? = nil, bottomConstraint: NSLayoutConstraint? = nil, margin: CGFloat = 16)
	{
		self.mainView = mainView
		self.importantElements = elements
		self.topConstraint = topConstraint
		self.bottomConstraint = bottomConstraint
		self.margin = margin
		
		startKeyboardListening()
	}
	
	// Starts listening to keyboard state changes
	func startKeyboardListening()
	{
		if observers.isEmpty
		{
			let didShowObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: onKeyboardShow)
			
			let didHideObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidHide, object: nil, queue: nil)
			{
				_ in
				self.lowerView()
			}
			
			observers = [didShowObserver, didHideObserver]
		}
	}
	
	// Stops listening for keyboard state changes
	func endKeyboardListening()
	{
		observers.forEach { NotificationCenter.default.removeObserver($0) }
		observers = []
	}
	
	private func onKeyboardShow(_ notification: Notification)
	{
		//print("STATUS: View adjusting to new keyboard status")
		
		guard let keyboardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect else
		{
			return
		}
		
		// If there are no important elements to display, doesn't need to react to keyboard display
		guard !importantElements.isEmpty else
		{
			return
		}
		
		let originalY = mainView.frame.origin.y - totalRaise
		let keyboardY = mainView.frame.height - keyboardSize.height
		let visibleAreaHeight = keyboardY - originalY
		
		let contentBottomY = importantElements.map { $0.frame(in: mainView).maxY }.max()!
		// print("STATUS: Content bottom Y: \(contentBottomY)")
		
		// In case all the elements are above the keyboard treshold, doesn't need to have the view raised
		guard contentBottomY > visibleAreaHeight else
		{
			// print("STATUS: All content fits into view naturally -> lowers view")
			lowerView()
			return
		}
		
		// Next tries to fit all elements to the remaining visible area
		let contentTopY = importantElements.map { $0.frame(in: mainView).minY }.min()!
		let contentHeight = contentBottomY - contentTopY
		
		if visibleAreaHeight > contentHeight
		{
			// If all elements could fit, checks if there is enough room for margins
			if visibleAreaHeight > contentHeight + 2 * margin
			{
				// In which case leaves a margin below the bottom element
				setRaise(to: contentBottomY + margin - keyboardY)
			}
			else
			{
				// If there wasn't enough room for margins, centers the important area on the visible view
				setRaise(to: contentBottomY - keyboardY + (visibleAreaHeight - contentHeight) / 2)
			}
		}
		else
		{
			// If all the components cannot be fit on the visible area checks if any of the views is currently in focus / first reponder
			if let firstResponderElement = firstResponderElement
			{
				let firstResponderTop = firstResponderElement.frame(in: mainView).minY
				let firstResponderBottom = firstResponderElement.frame(in: mainView).maxX
				let maxRaise = firstResponderTop - margin
				
				// If there is a first responder element, checks whether the first responder element should be made more visible
				if firstResponderBottom + margin > visibleAreaHeight + totalRaise
				{
					// Moves the view until the element is visible. Makes sure the top of the element stays visible too
					setRaise(to: max(firstResponderBottom + margin, maxRaise))
				}
					// Also checks if the view is raised too much for the element to show properly
				else if totalRaise > maxRaise
				{
					setRaise(to: maxRaise)
				}
			}
			else
			{
				// If any of the views wasn't the first responder, raises the view as much as possible without hiding the top element(s)
				let minRaise = contentTopY - margin
				if totalRaise < minRaise
				{
					setRaise(to: minRaise)
				}
			}
		}
	}
	
	private func setRaise(to raise: CGFloat)
	{
		raiseView(by: raise - totalRaise)
	}
	
	private func raiseView(by raise: CGFloat)
	{
		totalRaise += raise
		
		// mainView.translatesAutoresizingMaskIntoConstraints = true
		// mainView.frame.origin.y -= raise
		UIView.animate(withDuration: 0.5)
		{
			if let bottomConstraint = self.bottomConstraint
			{
				bottomConstraint.constant += raise
			}
			else
			{
				self.topConstraint?.constant -= raise
			}
			self.mainView.layoutIfNeeded()
		}
		
		/*
		let newY = mainView.frame.origin.y - raise
		UIView.animate(withDuration: 1.0)
		{
		self.mainView.frame = CGRect(x: self.mainView.frame.origin.x, y: newY, width: self.mainView.frame.width, height: self.mainView.frame.height)
		self.mainView.layoutSubviews()
		}*/
	}
	
	private func lowerView()
	{
		//print("STATUS: Setting view to original state")
		setRaise(to: 0)
	}
}
