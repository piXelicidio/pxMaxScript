macroScript VertCopyPaste category:"pX Tools" buttonText:"Vert CopyPaste"
(
	local VertPosData 
	local vertSel 
	
	rollout roll_copypaste "Vertex Copy/Paste" width:162 height:105
	(
		button btnCopy "Copy vert. Pos." pos:[19,16] width:127 height:26
		button btnPasteOposite "Paste Oposite" pos:[18,58] width:125 height:24
		
		on btnCopy pressed  do
		(
			
			vertSel = (polyOp.GetVertSelection $ ) as array
			if vertSel.count == 1 then
			(
				vertPosData = polyOp.GetVert $  vertSel[1]
				print vertPosData
			)				
		)
		on btnPasteOposite pressed  do
		(
			vertSel = (polyOp.GetVertSelection $ ) as array
			if vertSel.count == 1 then
			(
				opVert = VertPosData
				opVert.x = -opVert.x
				polyOp.SetVert $  vertSel[1] opVert
			)
		)
	)
	
	rf = newRolloutFloater "Vert. CopyPaste" 200 120
   addRollout roll_copypaste rf	
)