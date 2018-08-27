macroscript WireThisM category:"pX-Misc" tooltip:"Object Material Wire Toggle"
(
	on isEnabled do
	(
		result = false
		if (selection.count==1)	then 
			if ($.material != undefined) then result = true		
	)
	on execute do
	(
		$.material.wire = not $.material.wire
	)
) 