-- Project Panel: Context awere panel with project tools and shortcuts.

--macroscript ProjectPanel category:"pX Tools" 
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
		
	
	
	PPFloater = newRolloutFloater "Project Panel" PanelWidth 400
	addRollout ProjectPanel PPFloater
	--addRollout ScriptList PPFLoater 	
	
	include @"F:\_px\3D\MaxScripts\_common\RollBuilder.mxs"
	
	function BuildTestRoll =
	(
		local rc = rolloutCreator "rollMatrix" "Rollout Matrix"
		rc.begin()
		local matrixControlTypes = #(#button, #checkButton)
		local footerButtonNames = #("Add", "Remove", "Up", "Edit")
		local footerButtonCaptions = #("+","-","^","Edit")
		RollMatrix_AddControls rc 5 matrixControlTypes #(120,15) 20
		RollMatrix_AddFooterButtons rc footerButtonNames footerButtonCaptions 40 20 posy:(20*5+10)
		print rc.str
		rc.end()
		--return 
		(rc)
	)
	
	local testRoll = BuildTestRoll()
	addRollout testRoll.def PPFloater
	
	cui.registerDialogBar PPFloater
	
)
