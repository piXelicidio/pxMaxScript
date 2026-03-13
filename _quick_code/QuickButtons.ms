macroscript QuickButtons tooltip:"Quick Buttons" category:"pX Tools" 
(
	rollout Actions "Quick Buttons" 
	(
		button btnPosToZero "Pos to (0,0,0)"
		button btnScaleToOne "Scale to (1,1,1)"
		button btnRotationToZero "Rot. to (0,0,0)"
		group "select" (
			button btnSelInvert "Select Invert"
			button btnSelAll "Select All"
			button btnSelNone "Select None"			
		)
		group "viewport" 
		(
			button btnToggleTextures "Toggle Textures"
		)
		
			
		on btnPosToZero pressed do
		(
			undo "Pos to (0,0,0)" on
			(
				for obj in selection do				
				(	
					obj.pos = [0,0,0]
				)				
			)
			DestroyDialog Actions
		)
		
		on btnScaleToOne pressed do
		(
			undo "Scale to [1,1,1]" on
			(
				for obj in selection do
				(				
					obj.scale = [1,1,1]
				)
			)
			DestroyDialog Actions
		)
		
		on btnRotationToZero pressed do
		(
			undo "Rot. to Zero" on
			(
				for obj in selection do
				(				
					obj.rotation = (quat 0 0 0 1)
				)
			)
			DestroyDialog Actions
		)
		
		on btnSelInvert pressed do
		(
			actionMan.executeAction 0 "40044"
			DestroyDialog Actions
		)
		
		on btnSelAll pressed do 
		(
			actionMan.executeAction 0 "40021"
			DestroyDialog Actions
		)
		
		on btnSelNone pressed do
		(
			actionMan.executeAction 0 "40043"
			DestroyDialog Actions 
		)		
			
		on btnToggleTextures pressed do
		(
			local view = NitrousGraphicsManager.GetActiveViewportSetting()
			view.useTextureEnabled = (not view.useTextureEnabled)
			DestroyDialog Actions
		)
	)
	
	on execute do	 
	(
		CreateDialog Actions 150 250 pos:mouse.screenpos
	)
)