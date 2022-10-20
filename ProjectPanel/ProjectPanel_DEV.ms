-- Project Panel: Project context awere panel with shortcuts and tools.


-- DONE ---------
-- Show current project folder with button to open in browser.
-- Dynamic List of scripts shortcut buttons. 
-- Save/load state within projec folder.

-- TODO:
-- Solve one instance window: See Macroscript isChecked and CloseDialogs. See Macroscript scope.
-- ^- Maybe the trick to toggle dialogBar is Visible true/false. test.

--$DIST_ONLY$ macroscript ProjectPanel category:"pX Tools" 
(	
	local _SELF_SCRIPT_ = @"F:\_px\3D\MaxScripts\ProjectPanel\ProjectPanel_DEV.ms" --$DEV_ONLY$
	include @"F:\_px\3D\MaxScripts\_common\_SELF_INCLUDE_MACRO_.mxs"	--$DEV_ONLY$
	--
	include @"F:\_px\3D\MaxScripts\_common\IniFile.mxs"
	include @"F:\_px\3D\MaxScripts\_common\RollBuilder.mxs"
	
	if g_ProjectPanelwindow!=undefined then
	(
		if g_ProjectPanelwindow.open then
		(
			--TODO: Reset/close the old window. Is there a more convenient approach?
			--BUG: this doesn't work with macros, weird undefined function error
			cui.unRegisterDialogBar g_ProjectPanelWindow 
			closeRolloutFloater g_ProjectPanelWindow			
		)
	)
	
	local rollScripts_ref = undefined
	local rollProjectPanel_ref = undefined
	local ActionListScripts = undefined
	local currProject = ""
	local lastProject = undefined
	
	local PanelWidth = 200	
	local ini = IniFile()
	
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
		ini.currSection = "SCRIPTS" 
		local als = ActionListScripts
		local scriptsFileNames = als.getObjects()
		ini.writeArray "scripts" scriptsFileNames
	)
	
	function Scripts_LoadState =
	(	
		ini.currSection = "SCRIPTS"
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

	
	--events
	function Start =
	(
		currProject = (pathConfig.getCurrentProjectFolder())
		rollProjectPanel_ref.UpdateContext()
		Scripts_LoadState()
		callbacks.addScript #postProjectFolderChange ProjectPanel_FolderChanged id:#pxProjectChange				
	)
	
	-- Project Panel ----------------------------------------------------
	rollout rollProjectPanel "Project:"
	(			
		button btnOpenExplorer "Open In Explorer"
		
		--functions
		function UpdateContext =
		(			
			btnOpenExplorer.tooltip = currProject
			rollProjectPanel.Title = (getFilenameFile currProject)
			ini.filename = currProject + "\\" + "ProjectPanel.ini"	
		)
		
		
		on rollProjectPanel close do
		(
			Scripts_SaveState()
			callbacks.removeScripts id:#pxProjectChange
		)
		
		on btnOpenExplorer pressed do
		(
			ShellLaunch (currProject+@"\") ""
		)		
		
	)
	rollProjectPanel_ref = rollProjectPanel
	
	--Floater window ----------------------------------------------------
	global g_ProjectPanelWindow = newRolloutFloater "Project Panel" PanelWidth 400
	addRollout rollProjectPanel g_ProjectPanelWindow
		
	-- Scripts List  ------------------------------------------------------------------
	local rb = RollBuilder()	
	ActionListScripts = rb.CreateActionListRoll "_rollScripts_" "Scripts" PanelWidth 20 maxRows:20 rolloutFloater:g_ProjectPanelWindow
	rollScripts_ref = ActionListScripts.rollDef
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
			
	cui.registerDialogBar g_ProjectPanelWindow
	Start()	
	
)
