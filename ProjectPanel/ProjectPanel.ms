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
	rb = RollBuilder()
	
	ActionRoll = rb.CreateActionListRoll "_ActionRoll_" "Scripts" PanelWidth 20 maxRows:10 rolloutFloater:PPFloater 
	
	
		function btn_event idx =
		(
			print ("Pressed btn "+( idx as string))
		)
		ActionRoll.rollDef.action_event = btn_event
	
	cui.registerDialogBar PPFloater
	
)
