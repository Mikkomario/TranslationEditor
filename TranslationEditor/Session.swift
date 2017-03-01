//
//  Session.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Session keeps track of user choices within and between sessions
class Session
{
	// ATTRIBUTES	---------------
	
	static let instance = Session()
	
	private static let KEY_ACCOUNT = "agricola_account"
	private static let KEY_USERNAME = "agricola_username"
	private static let KEY_PASSWORD = "agricola_password"
	private static let KEY_PROJECT = "agricola_project"
	private static let KEY_AVATAR = "agricola_avatar"
	
	private var keyChain = KeychainSwift()
	
	
	// COMPUTED PROPERTIES	-------
	
	var projectId: String?
	{
		get { return self[Session.KEY_PROJECT] }
		set { self[Session.KEY_PROJECT] = newValue }
	}
	
	var avatarId: String?
	{
		get { return self[Session.KEY_AVATAR] }
		set { self[Session.KEY_AVATAR] = newValue }
	}
	
	private(set) var accountId: String?
	{
		get { return self[Session.KEY_ACCOUNT] }
		set { self[Session.KEY_ACCOUNT] = newValue }
	}
	
	private var userName: String?
	{
		get { return self[Session.KEY_USERNAME] }
		set { self[Session.KEY_USERNAME] = newValue }
	}
	
	private var password: String?
	{
		get { return self[Session.KEY_PASSWORD] }
		set { self[Session.KEY_PASSWORD] = newValue }
	}
	
	// Whether the current session is authorized (logged in)
	var isAuthorized: Bool { return userName != nil && password != nil }
	
	
	// INIT	-----------------------
	
	private init()
	{
		// Instance accessed statically
	}
	
	
	// SUBSCRIPT	---------------
	
	private subscript(key: String) -> String?
	{
		get { return keyChain.get(key) }
		set
		{
			if let newValue = newValue
			{
				keyChain.set(newValue, forKey: key)
			}
			else
			{
				keyChain.delete(key)
			}
		}
	}
	
	
	// OTHER METHODS	-----------
	
	func logIn(userName: String, password: String) throws
	{
		
	}
}
