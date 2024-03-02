macroscript ResetToMyStart tooltip:"Reset And Load MyStart.max" category:"pX Tools" 
(
	if checkForSave() do 
	(
		resetMaxFile #noPrompt
		loadMaxFile "F:\_px\3D\_commons\MyStart.max" useFileUnits:true quiet:true
	)
)