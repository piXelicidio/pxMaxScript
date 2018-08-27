maxSteps =25
AnimButtonState = true
sliderTime = 0
for j=0 to maxSteps-1 do
(
    
	vobj = $boxi
	StepDir =[15,0,50]
	newPos = obj.pos + StepDir

	R = (Ray NewPos [0,0,-1])

	Res = intersectRayScene  R
	if Res.count<1 then Break
			
	maxz = -1000	
	for i=1 to Res.count do
	(
		if (Res[i][2].pos.z > maxz) then
		(
			maxz = Res[i][2].pos.z
			NewPos = Res[i][2].pos	
		)
	)
	BezierDefaultParams.inTangentType = #smooth
	BezierDefaultParams.outTangentType = #smooth
	sliderTime = (j*10)-5
	obj.pos = (NewPos + Obj.pos)*0.5 + [0,0,5]
	BezierDefaultParams.inTangentType = #linear
	BezierDefaultParams.outTangentType = #linear
	sliderTime = (j*10)
	obj.pos = NewPos)
)
 