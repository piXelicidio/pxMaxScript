

utility px3DDisplacer "pX 3D Displacer" width:163 height:350
(
	local a,b
	
	function PickFilterPoly Obj = 
	( 
		(ClassOf Obj == Editable_Poly) and (Obj != b )
	)
	function PickFilterDisp Obj =
	(
		(Obj != a )
	)
	function InsideBox pt MinBox MaxBox =
	(
		Result = (pt.x > MinBox.x) and (pt.y > MinBox.y) and (pt.z > MinBox.z) 
		Result = Result and (pt.x < MaxBox.x) and (pt.y < MaxBox.y) and (pt.z < MaxBox.z)
	)
	
	pickbutton btnTarget "none" pos:[8,24] width:144 height:24 message:"Click to select an Editable_Poly object" filter:PickFilterPoly toolTip:""
	label lbl1 "Target (Editable_Poly):" pos:[8,8] width:112 height:16
	pickbutton btnDisplacer "none" pos:[28,69] width:104 height:24 message:"Click to Select Displacer Object" filter:PickFilterDisp
	label lbl2 "Displacer Object:" pos:[8,53] width:136 height:16
	button btnApply "Apply" pos:[13,105] width:60 height:50
	GroupBox grp1 "Options" pos:[3,163] width:156 height:92
	radiobuttons rdo1 "" pos:[90,117] width:46 height:32 labels:#("ADD", "SUB") columns:1
	label lbl19 "Operation:" pos:[83,102] width:51 height:16
	checkbox chkAffectSel "Selected Faces Only" pos:[7,181] width:145 height:20
	checkbox chkDisableUndo "Disable UNDO" pos:[7,199] width:145 height:20
	groupBox grp3 "About..." pos:[2,256] width:158 height:66
	label lbl7 "pX 3D Displacer" pos:[36,273] width:80 height:15
	label lbl8 "by Denys Almaral (piXel)" pos:[18,288] width:114 height:19
	label lbl9 " Version 1.0 -  June 2007" pos:[13,303] width:130 height:14
	
	
	on btnTarget picked obj do
	(
		btnTarget.Caption = obj.name
		a = obj
		when a deleted do 
		( 
			a = undefined
			btnTarget.Caption = "none"
		)
	)
	on btnDisplacer picked obj do
	(
		btnDisplacer.Caption = obj.name
		b = obj
		when b deleted do
		(
			b = undefined
			btnDisplacer.caption = "none"
		)
	)
	on btnApply pressed do
	(	
		if (a!=undefined) and (b!=undefined) then
		(
			SetWaitCursor()
			--- a target poly
			--- b diisplacer
			RayDir = [0,0,-1]
			SubAdd = 1  		-- -1 sub  +1 add
			myverts = #{}
			if rdo1.state==2 then SubAdd = -1
			AffectSel = ChkAffectSel.Checked
			
			TickCounter = TimeStamp()
			ProgressStart "Please wait..."
			
			if AffectSel then FSel = PolyOp.GetFaceSelection a;
			
			--maxDim?
			maxDim = a.max.x - a.min.x
			dim = a.max.y - a.min.y
			if dim>maxDim then maxDim = dim
			dim = a.max.z - a.min.z
			if dim>maxDim then maxDim = dim
			maxDim = (sqrt 3) * maxDim
			
			--NOrmals!
			NumNormals = 0
			NormalSum = [0,0,0]
			NumFaces = PolyOp.GetNumFaces a
			
			if AffectSel then BA = FSel else BA=#{1..NumFaces}			
			for i in BA do
			(
				--time stuf
			  	if  (mod i 100)==0 then
			  	(
			  		if ((TimeStamp() - TickCounter) > 1000 ) then
			  		(
			  			TickCounter = TimeStamp()
			  			cancel = not (ProgressUpdate  ( i*100/(PolyOp.GetNumVerts a) ) )			
			  		)
			  	)
				
				thisface = (PolyOp.GetFaceVerts	a i)
				vi = thisface[1]
				
				if True then 
				(
					v  = PolyOp.GetVert a vi
					if ( InsideBox v b.Min b.Max) then
					(
					 	NumNormals = NumNormals + 1
						N = PolyOp.GetFaceNormal a i
						NormalSum = NormalSum + N
	
						-- my active verts
						join myverts (thisface as BitArray)
	
					)
				)
			)
			ResultNormal = -(NormalSum / NumNormals)
			RayDir = ResultNormal * SubAdd
			
			--The magic here
			if chkDisableUndo.checked then undoOnOff = off else undoOnOff=on
			undo "pX3DDisplacer" undoOnOff
			(
				NumVerts = PolyOp.GetNumVerts a
				--if AffectSel then BA = VSel else BA =#{1..NumVerts}
				BA = myverts
				for i in BA do
				(
					--time stuf
				  	if  (mod i 100)==0 then
				  	(
				  		if ((TimeStamp() - TickCounter) > 1000 ) then
				  		(
				  			TickCounter = TimeStamp()
				  			cancel = not (ProgressUpdate  ( i*100/(PolyOp.GetNumVerts a) ) )			
				  		)
				  	)
					
					
					--Doit
					if True then
					(
						v = PolyOp.GetVert a i
						if ( InsideBox v b.Min b.Max) then
						(
							RayPos = v - (RayDir * maxDim)
							r = Ray RayPos RayDir
							r = intersectRay b r			
							if r != undefined then
							(
								SideOk = (Length (r.pos-RayPos)) < (Length (v - RayPos)) 
								if SideOk then
								(
									v = r.pos
									PolyOp.SetVert a i v
								)
							)	
							
						)--if InsideBox...
					)--If doit
				)--for
			)--undo
			UpDate a
			SetArrowCursor()
			ProgressEnd()	
		)--if a!=undefined...
	)--on BtnApply
)