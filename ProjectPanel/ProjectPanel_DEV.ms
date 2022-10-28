-- Project Panel: Project context awere panel with shortcuts and tools.


-- DONE ---------
-- Show current project folder with button to open in browser.
-- Dynamic List of scripts shortcut buttons. 
-- Save/load state within projec folder.
-- This scripts define a macro and run itself. Useful to put in startup folder
-- Toggle window and remember docking state


-- TODO:


--$DIST_ONLY$function DefineAndRunMacro = ( 
--$DIST_ONLY$local macroID = macroscript ProjectPanel category:"pX Tools" 
(	
	local _SELF_SCRIPT_ = @"F:\_px\3D\MaxScripts\ProjectPanel\ProjectPanel_DEV.ms" --$DEV_ONLY$
	include @"F:\_px\3D\MaxScripts\_common\_SELF_INCLUDE_MACRO_.mxs"	--$DEV_ONLY$	
	local EXECUTE_DEV = true --$DEV_ONLY$
	--
	include @"F:\_px\3D\MaxScripts\_common\IniFile.mxs"
	include @"F:\_px\3D\MaxScripts\_common\RollBuilder.mxs"
	
	local rollScripts_ref = undefined
	local rollProjectPanel_ref = undefined
	local ActionListScripts = undefined
	local currProject = ""
	local lastProject = undefined
	local executions = 0	
	local closedBy_max = false
	
	local PanelWidth = 200	
	local WindowOpen = false;
	local ProjectPanelWindow = undefined
	
	local ini = IniFile()
	ini.filename = pathConfig.getCurrentProjectFolder() + "\\" + "ProjectPanel.ini"	
	
	--LOCAL FUNCTIONS --------------------------------------------------------------------------
	function maxVer =
	(
		local mv = maxVersion()
		local res = mv[4] * 10
		local res = res + mv[5]
		-- 2020.0 => 220
		-- 2021.1 => 231
		-- 2022.3 => 243
		--
		(res)
	)
	
	function Scripts_SaveState =
	(
		ini.section = "SCRIPTS" 
		local als = ActionListScripts
		local scriptsFileNames = als.getObjects()
		ini.writeArray "scripts" scriptsFileNames
	)
	
	function Scripts_LoadState =
	(	
		ini.section = "SCRIPTS"
		local als = ActionListScripts
		local scriptsFileNames = ini.readArray "scripts";
		local items = #()
		for i=1 to scriptsFileNames.count do
		(
			local n = scriptsFileNames[i]
			items[i] = #(getFilenameFile n, n)
		)
		als.itemObjects = items
		als.SetRowCount items.count
		als.refreshCaptions()		
	)
	
	function ProjectPanel_FolderChanged =
	(		
		--fixing callback event firing twice
		if currProject != (pathConfig.getCurrentProjectFolder()) then
			(
				Scripts_SaveState()
				lastProject = currProject					
				currProject = pathConfig.getCurrentProjectFolder()
				rollProjectPanel_ref.UpdateContext()	
				Scripts_LoadState()
			)
	)
	
	function MaxIsClosing = 
	(
		local globalIni = (getDir #userMacros) + "//" + "g_ProjectPanel.ini"
		setINISetting globalIni "SETTINGS" "closedBy" "max" 		
		closedBy_max = true
	)

	
	--events
	function Start =
	(
		currProject = (pathConfig.getCurrentProjectFolder())
		rollProjectPanel_ref.UpdateContext()
		Scripts_LoadState()
		callbacks.addScript #postProjectFolderChange ProjectPanel_FolderChanged id:#projectPanel_folderChange
		callbacks.addScript #preSystemShutdown MaxIsClosing id:#projectPanel_maxIsClosing
	)
	
	function get_lastDockState =
	(
		ini.section = "SETTINGS"
		(ini.read "lastDockState") as name
	)
	
	function set_lastDockState state = 
	(
		ini.section = "SETTINGS";
		ini.write "lastDockState" (state as string)
	)
	
	function CloseWindow =
	(
		set_lastDockState (cui.getDockState ProjectPanelWindow)
		rollProjectPanel_ref.closingByCloseDialogs = true;
		cui.unRegisterDialogBar ProjectPanelWindow
		closeRolloutFloater ProjectPanelWindow
		WindowOpen = false	
	)
	

		
	function RestoreDocking =
	(		
		local lastDockState = get_lastDockState()
		local valid = findItem #(#cui_dock_left, #cui_dock_top, #cui_dock_right, #cui_dock_bottom ) lastDockState
		if valid then
		(
			cui.dockDialogBar ProjectPanelWindow lastDockState
		)
	)
	
	-- Project Panel ----------------------------------------------------
	rollout rollProjectPanel "Project:"
	(			
		local closingByCloseDialogs = false
		button btnOpenExplorer "Open In Explorer"
	
		
		--functions
		function UpdateContext =
		(			
			btnOpenExplorer.tooltip = currProject
			rollProjectPanel.Title = (getFilenameFile currProject)
			ini.filename = currProject + "\\" + "ProjectPanel.ini"	
		)
		
		on rollProjectPanel open do
		(
			
		)
				
		
		on rollProjectPanel close do
		(		
			if not closingByCloseDialogs then set_lastDockState #cui_floatable
			Scripts_SaveState()
			callbacks.removeScripts id:#projectPanel_folderChange
			callbacks.removeScripts id:#projectPanel_maxIsClosing
			if not closedBy_max then
			(
				local globalIni = (getDir #userMacros) + "//" + "g_ProjectPanel.ini"
				setINISetting globalIni "SETTINGS" "closedBy" "user" 	
			)
			WindowOpen = false; 
			updateToolbarButtons()
		)
		
		on btnOpenExplorer pressed do
		(
			ShellLaunch (currProject+@"\") ""
		)		
		
	)
	
	----MACROSCRIPTS EVENTS----------------------------------------		
	function MainExecute = 
	(
		executions += 1
		rollProjectPanel_ref = rollProjectPanel		
		
		--Floater window ----------------------------------------------------
		ProjectPanelWindow = newRolloutFloater "Project Panel" PanelWidth 400
		cui.registerDialogBar ProjectPanelWindow		
		WindowOpen = true;
		addRollout rollProjectPanel ProjectPanelWindow
			
		-- Scripts List  ------------------------------------------------------------------
		local rb = RollBuilder()	
		ActionListScripts = rb.CreateActionListRoll "_rollScripts_" "Scripts" PanelWidth 20 maxRows:20 rolloutFloater:ProjectPanelWindow
		rollScripts_ref = ActionListScripts.rollDef
		-- Scripts list events:
		function onAddItem idx =
		(
			local fname = getOpenFileName "Select Script" types:"MaxScript(*.ms, *.mxs, *.mse)|*.ms;*.mxs;*.mse|Python(*.py)|*.py|All(*.*)|*.*" 
			local result = undefined	
			if fname != undefined then 
			(
				result = #(getFileNameFile fname, fname);
			)
			--return
			(result)
		)
		function onAction itemCaption itemObject =
		(
			--print("run script: "+itemObject)
			if itemObject!=undefined then
			(	
				if maxVer() >= 231 then
				(
					executeScriptFile itemObject
				) else
				(	
				   fileIn itemObject
				)
			)
		)
		function onEdit itemCaption itemObject =
		(
			edit itemObject
			--return: undefined to not modify		
			(undefined)
		)
		ActionListScripts.onAddItem = onAddItem
		ActionListScripts.onItemAction = onAction
		ActionListScripts.onEditItem = onEdit
				
		
		Start()
		RestoreDocking();
	)
	
	--$DIST_ONLY$on execute do MainExecute()
	--$DIST_ONLY$on isChecked do (WindowOpen)
	--$DIST_ONLY$on closeDialogs do CloseWindow()
		
	
	if EXECUTE_DEV then MainExecute() --$DEV_ONLY$	
)
--$DIST_ONLY$ local globalIni = (getDir #userMacros) + "//" + "g_ProjectPanel.ini"
--$DIST_ONLY$ local dorun = (getINISetting globalIni "SETTINGS" "closedBy") == "max"
--$DIST_ONLY$ if dorun then (macros.run macroID))
--$DIST_ONLY$ DefineAndRunMacro()