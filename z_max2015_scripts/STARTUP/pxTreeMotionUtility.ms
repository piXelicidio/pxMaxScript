utility pxTreeMotion "pX Tree Motion" width:160 height:401
(
	GroupBox grp3 "Random Movement" pos:[7,8] width:145 height:211
	spinner spnAmpLeaves "Leaves " pos:[29,40] width:75 height:16 range:[0,100,0.4] type:#float scale:0.01
	spinner spnFreqLeaves "" pos:[103,40] width:44 height:16 range:[0,100,0.08] type:#float scale:0.01
	label lbl2 " Amp.         Freq." pos:[57,24] width:80 height:14
	spinner spnAmpBranches "Branches" pos:[24,60] width:80 height:16 range:[0,100,0.1] scale:0.01
	spinner spnFreqBranches "" pos:[103,60] width:44 height:16 range:[0,100,0.02] scale:0.01
	spinner spnAmpRoots "Roots" pos:[39,80] width:65 height:16 range:[0,100,0.4] scale:0.01
	spinner spnFreqRoots "" pos:[103,80] width:44 height:16 range:[0,100,0.01] scale:0.01
	button btnApply "Apply" pos:[38,164] width:77 height:20
	button btnClear "Clear" pos:[58,190] width:38 height:21
	GroupBox grp6 "About..." pos:[5,316] width:146 height:75
	label lbl5 "pX Tree Motion" pos:[31,334] width:78 height:15
	label lbl12 "by Denys Almaral  (piXel)" pos:[15,350] width:129 height:17
	label lbl13 "Version 1.0  -  May 2007" pos:[17,367] width:124 height:16
	GroupBox grp13 "Selected Nodes" pos:[7,227] width:144 height:85
	label lblLeaves "Leaves: 0" pos:[26,247] width:81 height:14
	label lblBranches "Branches: 0" pos:[17,264] width:91 height:12
	label lblRoots "Roots: 0" pos:[34,280] width:75 height:14
	button btn15 "Refresh" pos:[96,284] width:45 height:21
	GroupBox grp42 "Disable Axis..." pos:[18,108] width:123 height:45
	checkbox chkDisableX "X" pos:[26,126] width:29 height:17
	checkbox chkDisableY "Y" pos:[62,127] width:28 height:14
	checkbox chkDisableZ "Z" pos:[96,128] width:30 height:13 checked:true
	
	function RefreshCounters =
	(
			--Selected Nodes counters
		CountLeaves = 0
		CountBranches = 0
		CountRoots = 0
		for i=1 to $Selection.count do
		(
			obj = $Selection[i]
			if ( not (IsGroupMember obj)) then
			(			
				if (obj.parent == undefined) then CountRoots = CountRoots + 1 
				else
				(
					if (obj.Children.count == 0) then CountLeaves = CountLeaves + 1 
					else
					(
						CountBranches = CountBranches + 1
					)
				)	
			)
		)
		lblLeaves.caption = "Leaves: " + CountLeaves as string
		lblBranches.caption = "Branches: " + CountBranches as string
		lblRoots.caption = "Roots: " + CountRoots as string
	)
	
	
	on pxTreeMotion open do
	(
		RefreshCounters()
	)
	on btnApply pressed do
	(
		-- Tree Moviment simulation - by piXel sep/2005
		AmpRoots = spnAmpRoots.value
		AmpBranches = spnAmpBranches.value
		AmpLeaves = spnAmpLeaves.value
		FreqRoots = spnFreqRoots.value
		FreqBranches = spnFreqBranches.value
		FreqLeaves = spnFreqLeaves.value
		if chkDisableX.checked then DisX = 0 else DisX = 1
		if chkDisableY.checked then DisY = 0 else DisY = 1
		if chkDisableZ.checked then DisZ = 0 else DisZ = 1
		
		for i=1 to $Selection.count do
		(
		
			obj = $Selection[i]
			if ( not (IsGroupMember obj)) then
			(			
				-- Assign it Noise_Rotation Controller to simulate de action of soft winds
				C = Noise_Rotation()
				C.Seed = Random 1 100
				C.Fractal = False
				--Branches
				C.NoiseStrength = [AmpBranches * DisX, AmpBranches * DisY, AmpBranches * DisZ]
				C.Frequency = FreqBranches
				if (Obj.Children.count == 0) or (IsGroupHead Obj) then
				(
					C.NoiseStrength = [AmpLeaves * DisX, AmpLeaves * DisY, AmpLeaves * DisZ]
					C.Frequency = FreqLeaves
				)
				if (Obj.Parent == undefined ) then
				(
					C.NoiseStrength = [AmpRoots * DisX, AmpRoots * DisY, AmpLeaves * DisZ]
					C.Frequency = FreqRoots	
				)	
				-- Creating Controller List to preserve original rotation
				CList = Rotation_List()
				Obj.Rotation.Controller = Euler_XYZ()                -- para limpiar
				Obj.Rotation.Controller = CList
				Obj.Rotation.Controller.Available.Controller = C		
			)
		)

	)
	on btnClear pressed do
	(
		for i=1 to $Selection.count do
		(
			obj = $Selection[i]
			Obj.Rotation.Controller = Euler_XYZ()
		)
	)
	on btn15 pressed do
		RefreshCounters()
)