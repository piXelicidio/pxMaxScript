-- Convert MeshSmooth --to--> TurboSmooth 
-- from all objects selected.
-- Only if MeshSmooth is on TOP of the modifiers Stack;
for Obj in Selection do
(
	m = Obj.Modifiers[1]
	if (classof m) == MeshSmooth then
	(
		-- Remplazar por TurboSmooth
		NewM = TurboSmooth()
		NewM.iterations = m.iterations
		DeleteModifier Obj 1
		AddModifier Obj NewMx
	)		
)
