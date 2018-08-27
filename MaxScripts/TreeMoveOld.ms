-- Tree Moviment simulation - by piXel sep/2005

AmpRoot = 0.1
AmpBranches = 0.1
AmpLeafs = 0.2
FreqRoot = 0.01
FreqBranches = 0.02
FreqLeafs = 0.04

for i=1 to $Selection.count do
(
	-- Go through every object inserting Dummies between it and its parent.
	-- This achieve to preserve the actual Rotation of the object after a 
	-- Noise Controller have been applied to it.
	obj = $Selection[i]
	if (((classof obj) != Dummy) and not (IsGroupMember obj)) or (IsGroupHead obj)  then
	(			
		if (ClassOf obj.Parent) != Dummy then
		( 
			NewDummy = Dummy()
			NewDummy.Transform = Obj.Transform
			NewDummy.Parent = Obj.Parent
			Obj.Parent = NewDummy		
			NewDummy.BoxSize = [5,5,5]
			if NewDummy.Parent == undefined then NewDummy.BoxSize = [10,10,10]
			if Obj.children.count == 0 then NewDummy.BoxSize = [2,2,2]
		) else
		(
			NewDummy = Obj.Parent
		)
		
		-- Assign it Noise_Rotation Controller to simulate de action of soft winds
		C = Noise_Rotation()
		C.Seed = Random 1 100
		C.Fractal = False
		--Branches
		C.NoiseStrength = [AmpBranches, AmpBranches, 0]
		C.Frequency = FreqBranches
		if NewDummy.Parent == undefined then
		(
			C.NoiseStrength = [AmpRoot, AmpRoot, 0]
			C.Frequency = FreqRoot
		)
		if (Obj.Children.count == 0) or (IsGroupHead Obj) then
		(
			C.NoiseStrength = [AmpLeafs, AmpLeafs, 0]
			C.Frequency = FreqLeafs
		)	
		Obj.Rotation.Controller = C
	)
)