-- Project Panel: Context awere panel with project tools and shortcuts.

--macroscript?
(
	local currProject = ""
	local PPfloater = undefined
	local PanelWidth = 200
	
	
	rollout ProjectPanel "Project Folder"
	(
		label lblProject @"c:\" align:#right
		button btnOpenExplorer "Open In Explorer"		
		
		--functions
		function UpdateContextTo newPath =
		(
			currProject = newPath
			lblProject.text = newPath
		)
		
		function ProjectPanel_FolderChanged =
		(		
			--fixing callback event firing twice
			if currProject != (pathConfig.getCurrentProjectFolder()) then
				(
					currProject = pathConfig.getCurrentProjectFolder()
					UpdateContextTo currProject
				)
		)
	
		
		--events
		on ProjectPanel open do
		(
			UpdateContextTo (pathConfig.getCurrentProjectFolder())
			callbacks.addScript #postProjectFolderChange ProjectPanel_FolderChanged id:#pxProjectChange	
		)
		
		on ProjectPanel close do
		(
			callbacks.removeScripts id:#pxProjectChange
		)
		
		on btnOpenExplorer pressed do
		(
			ShellLaunch (currProject+@"\") ""
		)		
		
	)
	
	function footButtonPos btnsHeight numBtns colNum colWidth=
	(
		local pos = [0,0]
		pos.y = btnsHeight * numBtns + 10
		pos.x = (colNum-1)*(colWidth + 2)
		--result
		(pos)
	)
	
	function BuildDymScriptList rollName rollCaption maxButtons = (		
		bs = rolloutCreator rollName rollCaption
		
		local btnWidth = 150
		local btnHeight = 20
		local footBtnWidth = 40
		local WHparam = "width:" + (btnWidth as string) + " height:" + (btnHeight as string)		
		
		bs.begin()		
		--LOCALS
		bs.addLocal "buttonPressed" init:undefined
		bs.addLocal "buttons" init:#()
		bs.addLocal "checkboxes" init:#()
		bs.addLocal "btnAdd_pressed" init:undefined
		bs.addLocal "btnRemove_pressed" init:undefined
		bs.addLocal "btnUp_pressed" init:undefined
		bs.addLocal "btnEdit_pressed" init:undefined
		--CONTROLS
		for i=1 to maxButtons do
		(
			local btnName = "btn"+(i as string)
			local chkName = "chk"+(i as string)
			local POSparam = (btnHeight as string) + "* (" + (i as string) + "-1)]" 
			local btnPOSparam = " pos:[5," + POSparam
			local chkPOSparam = " pos:["+((btnWidth + 10) as string )+"," + POSparam
			bs.addControl #button (btnName as name) ("script"+(i as string)) paramStr:(WHparam + btnPOSparam)
			bs.addControl #checkbox (chkName as string) "" paramStr:chkPOSparam	
			
		)
		
		local footPOS1 = (footButtonPos btnHeight maxButtons 1 footBtnWidth) as string
		local footPOS2 = (footButtonPos btnHeight maxButtons 2 footBtnWidth) as string
		local footPOS3 = (footButtonPos btnHeight maxButtons 3 footBtnWidth) as string
		local footPOS4 = (footButtonPos btnHeight maxButtons 4 footBtnWidth) as string
		local fw = footBtnWidth as string
		bs.addControl #button #btnAdd "+" paramStr:("width:"+fw+" pos:"+footPOS1)
		bs.addControl #button #btnRemove "-" paramStr:("width:"+fw+" pos:"+footPOS2)		
		bs.addControl #button #btnUp "^" paramStr:("width:"+fw+" pos:"+footPOS3)		
		bs.addControl #button #btnEdit "Edit" paramStr:("width:"+fw+" pos:"+footPOS4)
		
		--EVENTS
		for i = 1 to maxButtons do
		(
			local btnName = "btn"+(i as string)
			bs.addHandler (btnName as name) #pressed filter:on codeStr:("if buttonPressed!=undefined then buttonPressed "+(i as string))
		)			
		
		bs.addHandler #btnAdd #pressed codeStr:("if btnAdd_pressed!=undefined then btnAdd_pressed()")
		bs.addHandler #btnRemove #pressed codeStr:("if btnRemove_pressed!=undefined then btnRemove_pressed()")
		bs.addHandler #btnUp #pressed codeStr:("if btnUp_pressed!=undefined then btnUp_pressed()")
		bs.addHandler #btnEdit #pressed codeStr:("if btnEdit_pressed!=undefined then btnEdit_pressed()")
			
		--rollout initialization
		bs.addText ("on "+rollName+" open do (")
		--initArrays
		for i=1 to maxButtons do 
		(
			local ii = i as string			
			bs.addText ("buttons[" + ii + "] = btn" + ii)
			bs.addText ("checkboxes[" + ii + "] = chk" + ii )
		)
		bs.addText ")"
		--print bs.str
		bs.end()		
		--return:
		(bs)
	)
	
	--DYNAMIC SCRIPTS ROLLOUT EVENTS 
	function OnScriptButtonPressed x =
	(		
		print ("Pressed: " + (x as string))
	)
	function OnBtnAdd_pressed =
	(
		print "add"
	)
	function onBtnRemove_pressed =
	(		
		for i=1 to DymScriptList.Checkboxes.Count do
		(
			if DymScriptList.Checkboxes[i].checked then 
			(
				DymScriptList.Buttons[i].caption = "" 
			)
		)
	)
	function onBtnUp_pressed =
	(
		print "up"
	)
	function onBtnEdit_pressed =
		
	(
		print "edit"
	)
	
	PPFloater = newRolloutFloater "Project Panel" PanelWidth 400
	addRollout ProjectPanel PPFloater
	--addRollout ScriptList PPFLoater 
	
	local dymScripts = BuildDymScriptList "DymScriptList" "Dym Script List" 10
	
	addRollout dymScripts.def PPFloater
	DymScriptList.buttonPressed = OnScriptButtonPressed	
	DymScriptList.btnAdd_pressed = OnBtnAdd_pressed
	DymScriptList.btnRemove_pressed = onBtnRemove_pressed
	DymScriptList.btnUp_pressed = OnBtnUp_pressed
	DymScriptList.btnEdit_pressed = OnBtnEdit_pressed
	print DymScriptList.buttons[4].caption
	
	cui.registerDialogBar PPFloater
	
)