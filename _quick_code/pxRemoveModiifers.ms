--make some dialogs, imput modifier name, allow other operations, add modifier, count, mass ops
--macroScript RemoveModifier category:"pX Tools" buttonText:"Remove Modifier"
(
	local mName = "OpenSubdiv"
	local count = 0
	for obj in  $ do
	(
		m = obj.modifiers[mName]
		print obj.modifiers.count
		if m!=undefined then 
		(
			deleteModifier obj m
			count = count + 1
		)
	)
	print count
)