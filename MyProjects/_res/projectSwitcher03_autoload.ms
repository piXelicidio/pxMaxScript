-- projectSwitcher v0.3 for 3dsmax 9+ - (c) 10.04.07 - 05.02.08 Martin Breidt (martin@breidt.net)
-- Macroscript tool for quickly switching between previously used project folders
--
-- This code is released under "Quote ware" license:
--      If you use this tool in a production environment with a group of more than two people,
--      or have used it in the past under such conditions, then you are obliged to tell 
--      me (martin@breidt.net) about it and allow me to list that project title and your 
--      company name as a reference on my website http://scripts.breidt.net
--
--
-- New in v0.3:
-- * Automatic Project Switching: When opening the file c:\projects\myproject\scenes\file.max, this function will 
--   automatically set c:\projects\myproject\ as the new project folder. Thanks to Tollef Roe Steen for the suggestion.
-- * No longer a macroscript; can be automatically run when 3ds Max starts
--
-- Installation: 
-- For automatic startup, just copy this script into your scripts\startup folder and restart 3ds Max.
--
-- Usage:
-- Running the action will produce a small floating dialog with a list of all previously used project folders
-- which you can select for fast switching. The dialog can be resized and docked. Note that it currently does
-- not track project folders that were opened directly using the standard 3ds Max GUI (e.g File > Project)
--
-- Press 'X' button to remove a project from the list (this will NOT modify anything in your project, just remove it from the list). 
-- Press 'Set' button to switch to or create a new project folder.
-- Press 'A' switch to enable Automatic Project Switching: after you load a scene file, projectSwitcher will
--           search for a "scenes" subdirectory in the file path and set the project to the containing folder.
-- Press 'A' switch with SHIFT to enter a new default name (e.g. scenes) for the directory that holds the .max scene files.
--
--
-- Note:
-- A small bug in 3ds Max 2008 causes projectSwitcher to always show a Browse-Folder-Dialog when switching projects.
-- This can be fixed by manually editing the file Macro_SetProjectFolder.mcr in the 
-- <3dsmax_root>\ui\macroscripts directory and changing
--
--    local _SetProjectFolder_macro_option_promptUser
--    local _SetProjectFolder_macro_option_newFolder
--
-- in line 25 and 26 to
--
--    global _SetProjectFolder_macro_option_promptUser
--    global _SetProjectFolder_macro_option_newFolder
--
-- Save the .mcr file and restart 3ds Max. This should return normal functionality for projectSwitcher
--

(
	global projectSwitcherCB
	global projectSwitcher_rollout	-- declare this global so the callback can access the rollout

	local debug = false
	
	fn projectSwitcherCB = (
		-- called whenever the project was switched; called for each directory -> suboptimal performance	
		projectSwitcher_rollout.appendIfNew projectSwitcher_rollout.prjList (pathConfig.getCurrentProjectFolder())
		projectSwitcher_rollout.refreshDL()
	)

	-- try to remove old dialog frist
	try (
		cui.UnRegisterDialogBar projectSwitcher_rollout
	) catch ()
	try (
		DestroyDialog projectSwitcher_rollout
	) catch ()

	rollout projectSwitcher_config "Project Switcher Config" width:280 (
		label l1 "Set this to the default name of the folder that contains" align:#left
		label l2 "your .max scene files (e.g. scenes)" align:#left
		editText sceneFolderTxt "Scene folder name: " width:250
		button okB " OK " width:50 across:2
		button cancelB " Cancel " width:50
		
		on projectSwitcher_config open do (
			sceneFolderTxt.text = projectSwitcher_rollout.sceneDir
		)
		on okB pressed do (
			projectSwitcher_rollout.sceneDir = sceneFolderTxt.text
			destroyDialog projectSwitcher_config
		)
		on cancelB pressed do destroyDialog projectSwitcher_config
	) -- end: rollout projectSwitcher
	
	rollout projectSwitcher_rollout "Project Switcher" width:390 height:32 (
		local prjList, prjListSel, iniFileName
		
		local dd_w = 310
		local dockState
		local sceneDir = "scenes"
		
		-------------- UI
		dropdownList prjDDlist "" pos:[5,5] width:dd_w height:21
		button delPrjBtn "X" pos:[dd_w + 5, 5] width:12 height:21 toolTip:"Remove project from list (will not delete any files)"
		button newPrjBtn "Set" pos:[dd_w + 20, 5] width:25 height:21 toolTip:"Set/create new project folder"
		checkbutton autoBtn "A" pos:[dd_w + 50, 5] width:12 height:21 toolTip:"Automatically set project folder when opening files. Press SHIFT to set the default folder name for scene files"
		button aboutBtn "?" pos:[dd_w + 65, 5] width:12 height:21 toolTip:"About/Help"
		
		-------------- functions
		fn refreshDL = (
		-- recreate dropdown list items and selection
			sort prjList
			local p = pathConfig.getCurrentProjectFolder()
			local s = findItem prjList p
			prjDDlist.items = prjList
			prjDDlist.selection = s
		)
		
		fn appendIfNew arr itm = (
		-- append itm to array arr if it is not in there yet
			if debug then format "findItem = %\n" (findItem arr itm)
			if (findItem arr itm)==0 then ( -- new item not yet in array
				append arr itm
			)
		)

		fn removeAutoCallback = (
			format "projectSwitcher: Removed autoswitch project callback\n"
			callbacks.removeScripts id:#projectSwitcher_cb
		)		

		fn installAutoCallback = (
			-- install file open callback
			-- callback code by Tollef Roe Steen
			removeAutoCallback()
			cbstr = 
			   "( scenePath = maxFilePath
				for i = 1 to scenePath.count do (
					currentLeaf = pathConfig.stripPathToLeaf scenePath
					scenePath = pathConfig.removePathLeaf scenePath
					if currentLeaf == \"" + sceneDir + "\" or currentLeaf == \"scenes\\\\\" then 
					(
						format \"projectSwitcher: Auto-switching to project % after opening file\\n\" scenePath
						pathConfig.doProjectSetupStepsUsingDirectory scenePath
						global projectSwitcher_rollout
						if (classof projectSwitcher_rollout)==RolloutClass and
						projectSwitcher_rollout.open then (
							projectSwitcher_rollout.appendIfNew projectSwitcher_rollout.prjList (pathConfig.getCurrentProjectFolder())
							projectSwitcher_rollout.refreshDL()
						)
						exit
					)
				) )"
			-- callbacks.notificationParam() == 2 -->  render preset file			
			callbacks.addScript #filePostOpen cbstr id:#projectSwitcher_cb	
			format "projectSwitcher: Installed autoswitch project callback\n"
			
		) -- end: fn installAutoCallback
				
		-------------- events
		on aboutBtn pressed do (
			local m = "(c) 07-08 Martin Breidt (martin@breidt.net)\n\n"
			append m "Usage:\n"
			append m "    * Select a previous project from the list to load it.\n"
			append m "    * Press 'X' to remove a project from the list.\n"
			append m "    * Press 'Set' to select/create a new project.\n"
			append m "    * Enable 'A' to automatically set the project folder when a file is loaded.\n"
			append m "      Click 'A' with SHIFT to set the default project folder name (e.g. scenes)\n"
			append m "\nThe dialog can be resized and docked at the top or bottom.\n"
			append m "Information about used projects and dialog size is saved in an .ini file.\n"
			messageBox m title:"About Project Switcher v0.3" beep:false
		)
		
		on delPrjBtn pressed do (
		-- remove currently selected project from list
			if prjDDlist.items.count > 1 then (
				local s = prjDDlist.selection
				deleteItem prjList s
				-- switch to next entry 
				if prjList.count > 0 then (
					local next = amax (prjDDlist.selection-1) 1
					pathConfig.doProjectSetupStepsUsingDirectory prjList[next]
				)
				refreshDL()
			)
		) -- end: on delPrjBtn
		
		on newPrjBtn pressed do (
		-- invoke project folder dialog
			pathConfig.doProjectSetupSteps()
			if debug then format "Current project folder: %\n" (pathConfig.getCurrentProjectFolder())
			appendIfNew prjList (pathConfig.getCurrentProjectFolder())
			if debug then format "prjList = %\n" prjList
			refreshDL()
		) -- end: on newPrjBtn
	
		on prjDDlist selected itm do (
			if debug then format "Setting project to item %: %\n" itm prjList[itm]
			pathConfig.doProjectSetupStepsUsingDirectory prjList[itm]
			if debug then format "Current project = %\n" (pathConfig.getCurrentProjectFolder())

		) -- end: on prjDDlist
	
		on autoBtn changed val do (
		-- install/setup the auto project load callback
			local updateCB = true
			if keyboard.shiftPressed then (
				local oldDir = sceneDir
				autoBtn.state = val = not val
				createDialog projectSwitcher_config modal:true
				if sceneDir==oldDir then updateCB=false
			)
			if updateCB then (
				if val then installAutoCallback() else removeAutoCallback()
			)
		)
	
		on projectSwitcher_rollout resized newSize do (
			local delta = (newSize.x - 390)
			if debug then format "resized by %\n" delta
			prjDDlist.width = dd_w + delta
			delPrjBtn.pos.x = dd_w + 5 + delta
			newPrjBtn.pos.x = dd_w + 20 + delta
			autoBtn.pos.x = dd_w + 50 + delta
			aboutBtn.pos.x = dd_w + 65 + delta
		) -- end: on resized
	
		on projectSwitcher_rollout open do (
			if debug then clearListener()
			if debug then print "OPEN"
			
			prjList = #()
			prjListSel = 0
	
			iniFileName = ((pathConfig.getDir #plugcfg) + "\projectSwitcher.ini")
			
			-- read list of project directories from INI file
			key_array = getINISetting iniFileName "Projects"
			for k in key_array do (
				if debug then format "Reading key %\n" k
				local val = getIniSetting iniFileName "Projects" k
				if val.count > 0 then append prjList val
			)
			-- add current project folder if not already present
			appendIfNew prjList (pathConfig.getCurrentProjectFolder())
			
			-- load INI settings
			local diagWidthVal = getINISetting iniFileName "Dialog" "Width"
			if debug then format "Dialog width = %\n" diagWidthVal
			if diagWidthVal.count > 0 then (
				try (
					projectSwitcher_rollout.width = (diagWidthVal as integer)
				) catch (
					format "projectSwitcher: Error parsing dialog width from ini file\n"
				)
			)

			local autoSwitchVal = getINISetting iniFileName "Dialog" "Auto"
			if autoSwitchVal.count > 0 then (
				try (
					autoBtn.checked = (autoSwitchVal as booleanclass)
				) catch (
					format "projectSwitcher: Error parsing auto switch from ini file\n"
				)
			)

			-- load name of folder that contains the .max scenes; normally, this is "scenes"
			local sceneDirVal = getINISetting iniFileName "Dialog" "sceneDir"
			if sceneDirVal.count > 0 then (
				sceneDir = sceneDirVal
			)
			
			if autoBtn.checked then (
				-- install file open callback
				installAutoCallback()
			) -- end: if autoBtn
			
			-- finally, refresh the list of projects
			refreshDL()

			-- register dialog
			cui.RegisterDialogBar projectSwitcher_rollout minSize:[390, 32] maxSize:[-1,32] style:#(#cui_dock_horz, #cui_floatable, #cui_handles)

			dockState = getINISetting iniFileName "Dialog" "DockState"
			if dockState.count > 0 then (
				-- found key, so set dialogBar accordingly
				if debug then format "loaded dockState = %\n" dockState
				try (
					cui.DockDialogBar projectSwitcher_rollout (dockState as name)
				) catch (
					format "projectSwitcher: Error setting dock state % from ini file\n" dockState
				)
			)
			
			-- install callback event for catching direct changes to project settings
--			callbacks.removeScripts id:#projectSwitcherCB
--			callbacks.addScript #systemPostDirChange "projectSwitcherCB()" id:#projectSwitcherCB	
		) -- end: on open
		
		on projectSwitcher_rollout close do (
			if debug then print "CLOSING"
			-- save current settings to INI file
			delIniSetting iniFileName "Projects"
			for i = 1 to prjList.count do (
				if debug then format "Writing project % to ini file\n" i
				local good = setINISetting iniFileName "Projects" ("Dir" + (i as string)) prjList[i]
				if not good then messageBox "Error writing to INI file"
			)
			setINISetting iniFileName "Dialog" "Width" (projectSwitcher_rollout.width as string)
			setINISetting iniFileName "Dialog" "Auto" (autoBtn.checked as string)
			setINISetting iniFileName "Dialog" "sceneDir" sceneDir
			-- save dock state to INI file
			if dockState!=undefined then (
				if debug then format "Saving dockState = %\n" dockState
				setINISetting iniFileName "Dialog" "DockState" dockState
			)
			-- remove callback
			removeAutoCallback()
		) -- end: on close
		
		on projectSwitcher_rollout moved x do (
			if debug then format "dialog moved to %\n" x
			if projectSwitcher_rollout.dialogBar then (
				-- rollout is a registered dialog bar
				dockState = (cui.getDockState projectSwitcher_rollout)
				if debug then format "dockState = %\n" dockState
			) 
		) -- end: on moved		
	) -- end: rollout
	createDialog projectSwitcher_rollout
)
