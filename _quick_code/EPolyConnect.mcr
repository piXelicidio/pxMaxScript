--Generic connect editable poly: Vertices or Edges (and maybe more..)
macroScript EpolyConnect category:"pX Tools" buttonText:"EPoly Connect"
(
	if subObjectLevel == 1 then
	(
		macros.run "Editable Polygon Object" "EPoly_VConnect"
	) 
	else if subObjectLevel == 2 then
	(
		macros.run "Editable Polygon Object" "EPoly_EConnect"
	)
)