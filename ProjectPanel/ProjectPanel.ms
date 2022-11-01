-- Project Panel: Project context awere panel with shortcuts and tools.


-- DONE ---------
-- Show current project folder with button to open in browser.
-- Dynamic List of scripts shortcut buttons. 
-- Save/load state within projec folder.
-- This scripts define a macro and run itself. Useful to put in startup folder
-- Toggle window and remember docking state


-- TODO:


function DefineAndRunMacro = ( 
local macroID = macroscript ProjectPanel category:"pX Tools" 
(	
	--
	struct IniFile
	(
		filename,
		section,
		
		--wrapping:
		function read key =
		(
			(getINISetting filename section key)
		),
	
		function write key value =
		(
			(setINISetting filename section key (value as string))
		),
		
		function remove key =
		(
			delIniSetting filename section key
		),
		
		function removeSection =
		(
			delIniSetting filename section
		),
		
		function hasKey key =
		(
			(hasINISetting filename section key)
		),
		
		function hasSection =
		(
			(hasINISetting filename section)
		),
		
		--extending:
		function writeArray ArrName ArrValues =
		(		
			write (ArrName+"_count") ArrValues.count
			for i=1 to ArrValues.count do
			(
				write (ArrName+"_"+(i as string)) (ArrValues[i] as string)
			)
	
		),
		
		function readArray ArrName =
		(
			local count = read (ArrName+"_count") 
			local result = #()
			if count!="" then
			(
				count = count as number
				for i = 1 to count do
				(
					result[i] = read (ArrName+"_"+(i as string))
				)
			)
			--return
			(result)
		)
		
	)
	
	--Helper function to use with rolloutCreator class,
	--parameter rci: an instance to a rolloutCreator
	struct RollBuilder 
	(
		function AddControlMatrix rci maxRows controlTypes controlNames widths height = 
		(
			--rci = rolloutCreator Instance
			--array of controls locals 
			local ctrlStr = #()
			for i=1 to controlTypes.count do
			(
				ctrlStr[i] = controlTypes[i] as string		
			)
			local controlNamesSep = #()	--names separated with commas
			for j = 1 to controlTypes.count do
			(
				controlNamesSep[j] = ""
			)
			local pos = [0,0]
			for j=1 to controlTypes.count  do
			(				
				for i=1 to maxRows do
				(				
					local ii = i as string
					local H = "height:"+(height as string)
					
					pos.y = (i-1) * height 			
					
					
					local W = " width:" +(widths[j] as string ) 				
					local posStr = " pos:"+(pos as string)
					local cName = (controlNames[j] + ii)
					
					rci.addControl controlTypes[j] cName "" paramStr:(H + W + posStr)
					controlNamesSep[j] =  controlNamesSep[j]+ ","+ cName 
					
				)
				pos.x = pos.x + widths[j] --+ 2
			)
			rci.AddText "--Arrays"
			for j=1 to controlTypes.count do
			(
				local s = substring controlNamesSep[j] 2 -1
				rci.addLocal (controlNames[j]+"_arr") init:("#("+s+")")
			)
			rci.AddText "--Pointers"
			local EventPointers = #()
			for j=1 to controlTypes.count do
			(			
				EventPointers[j] = controlNames[j]+"_event" 
				rci.addLocal (EventPointers[j]) init:undefined
			)
			rci.AddText "--Events"
			for j=1 to controlTypes.count  do
			(				
				for i=1 to maxRows do
				(
					local ii = i as string
					local s = "on "+ controlNames[j]+ii +" pressed do (if "
					local s = s + EventPointers[j] + "!=undefined then " + EventPointers[j] + " " + ii+ ")"
					rci.addText s
				)
			)
			rci.AddText "--"
		),
	
		function AddButtonRow rci names captions width height posy:0 =
		(
			--rci = rolloutCreator Instance
			for i=1 to names.count do
			(
				local W = " width:" + (width as string)
				local H = " height:" + (height as string)
				local p = [5 + (i-1)*width, posy]
				local posStr = " pos:" + (p as string)
				rci.addControl #button ("btn"+names[i]) Captions[i] paramStr:(H + W + posStr)
			)
			rci.AddText "--"
			local fEventName = "footerBtn_Event"
			rci.AddLocal fEventName init:undefined
			rci.AddText "--"
			--TODO: naa... better to put all footerns buttons in a single Event pointer
			for i=1 to names.count do
			(
				local cName = "btn"+ names[i]			
				local s = "on " + cName + " pressed do (if "
				s = s + fEventName+"!=undefined then "+ fEventName+" \""+names[i]+"\" )"
				rci.addText s
			)
		),
		
		function CreateActionListRoll rollName rollCaption FullWidth height maxRows:10 startY:0 rolloutFloater: =
		(
			struct ActionList 
			(
				rollDef,			
				maxRows,
				rowCount = 0,
				rowHeight,
				itemObjects = #(),
				
				--EVENTS
				--onAddItem(idx):should return #(string, obj)
				onAddItem,
				onItemAction,
				onEditItem,
				
				function init =
				(
					--Call this after 
					for i=1 to rollDef.edit_arr.count do
					(					
						rollDef.edit_arr[i].caption = ";"
						rollDef.edit_arr[i].tooltip = "Edit"
						rollDef.action_arr[i].caption = "item " + (i as string)
						rollDef.action_arr[i].tooltip = "Execute!"
						rollDef.up_arr[i].caption = "^" 
						rollDef.up_arr[i].tooltip = "Move to first"
						rollDef.remove_arr[i].caption ="X"
						rollDef.remove_arr[i].tooltip ="Remove"
					)
					rollDef.up_arr[1].enabled = false;
					rollDef.btnAdd.tooltip = "Add..."
				),
				function setRowCount N =
				(
					if N > maxRows then N = maxRows
					rowCount = N
					for i=1 to maxRows do
					(
						local show = (i <= N)
						rollDef.edit_arr[i].visible = show;
						rollDef.action_arr[i].visible = show;
						rollDef.up_arr[i].visible = show;
						rollDef.remove_arr[i].visible = show;
					)
					rollDef.height = (N+1.2) * rowHeight
					rollDef.btnAdd.pos.y = (N)*rowHeight
					rollDef.btnAdd.pos.x = 0;
					if N<maxRows then 
					( rollDef.btnAdd.enabled = true)
					else (rollDef.btnAdd.enabled = false)
				),
				
				function btnAdd_event =
				(
					if rowCount < maxRows then 
					(				
						
						if (onAddItem != undefined) then
						(
							local itemInfo = onAddItem rowCount
							if itemInfo != undefined then
							(
								setRowCount (rowCount + 1)
								rollDef.action_arr[rowCount].caption = itemInfo[1]
								itemObjects[rowCount] = itemInfo
							) 
						) 
					)
				),
				
				function refreshCaptions =
				(
					for i=1 to rowCount do
					(
						if itemObjects[i] != undefined then
						(
							rollDef.action_arr[i].caption = itemObjects[i][1]
						)
					)
				),
				
				function remove_event itemIdx =
				(
					if rowCount>0 then
					(
						deleteItem itemObjects itemIdx
						refreshCaptions()
						print ( "removing "+(itemIdx as string));
						setRowCount (rowCount - 1);
					)
				),
				
				function action_event itemIdx =
				(
					--edit itemObjects[itemIdx][2]
					if onItemAction!=undefined then
					(
						local c = undefined
						local obj = undefined
						if itemObjects [itemIdx]!=undefined then
						(
							c = itemObjects[itemIdx][1]
							obj = itemObjects[itemIdx][2]
						)
						onItemAction c obj
					)
				),
				
				function up_event itemIdx =
				(
					if itemIdx > 1 then 
					(
						local tmp = itemObjects[itemIdx]
						itemObjects[itemIdx] =itemObjects[itemIdx-1]
						itemObjects[itemIdx-1] = tmp
						refreshCaptions()
					)
				),
				
				function edit_event itemIdx =
				(				
					if onEditItem!=undefined then
					(
						local c = undefined
						local obj = undefined
						if itemObjects [itemIdx]!=undefined then
						(
							c = itemObjects[itemIdx][1]
							obj = itemObjects[itemIdx][2]
						)
						local result = onEditItem c obj
						if result!=undefined then
						(
							itemObjects[itemIdx][1] = result[1]
							itemObjects[itemIdx][2] = result[2]
							refreshCaptions()
						)
					)
				),
				
				function getObjects =
				(
					local result = #()
					for i =1 to itemObjects.count do result[i] = itemObjects[i][2];
					(result)
				)			
				
			)
			
			local al = ActionList()
			al.maxRows = maxRows
			al.rowHeight = height
			local rci = rolloutCreator rollName rollCaption
			rci.begin()
			local cTypes = #(#button, #button, #button, #button)
			local cNames = #("edit", "action", "up","remove")
			local H = height
			local b1Width = FullWidth-(H+2)*3 - 8
			local cWidths = #(H, b1Width, H, H)
			AddControlMatrix rci maxRows cTypes cNames cWidths H
			rci.addControl #button "btnAdd" "+" paramStr:("height:"+(H as string)+ " width:"+(H as string))
			rci.addLocal "btnAdd_event"
			rci.addText "on btnAdd pressed do (btnAdd_event())"
			--
			rci.end()
			--print rci.str
			--
			al.rollDef = rci.def
			if (rolloutFloater==unsupplied) then 
			( 
				--If NOT provided then ActionList.init() must be called after adding the rollout or creating a dialog
			)
			else
			(
				addRollout al.rollDef rolloutFloater
				al.init()
				al.setRowCount 0
				al.rollDef.btnAdd_event = al.btnAdd_event
				al.rollDef.remove_event = al.remove_event
				al.rollDef.action_event = al.action_event
				al.rollDef.up_event = al.up_event
				al.rollDef.edit_event = al.edit_event
			)
				
			--return
			(al)
		)
	)
	
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
	
	on execute do MainExecute()
	on isChecked do (WindowOpen)
	on closeDialogs do CloseWindow()
		
	
)
 local globalIni = (getDir #userMacros) + "//" + "g_ProjectPanel.ini"
 local dorun = (getINISetting globalIni "SETTINGS" "closedBy") == "max"
 if dorun then (macros.run macroID))
 DefineAndRunMacro()
