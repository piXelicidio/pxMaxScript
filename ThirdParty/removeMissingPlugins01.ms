-- removeMissingPlugins v0.15 for 3ds Max 2008+
-- (c) 2010 M. Breidt (martin@breidt.net)
--
-- This code is released under "Quote ware" license:
--      If you use this tool in a production environment with a group of more than two people,
--      or have used it in the past under such conditions, then you are obliged to tell 
--      me (martin@breidt.net) about it and allow me to list that project title and your 
--      company name as a reference on my website http://scripts.breidt.net
--
-- Replaces ALL missing plugins in current scene with default objects
-- This makes some pretty drastic changes to your scene, so USE WITH CARE!
--

(
	
	-- get list of missing plugin classes
	str = stringStream ""
	apropos "*missing*" to:str
	seek str 0
	cls = #()
	while not (eof str) do (
		ln = readLine str
		tk = filterString ln " "
		if tk.count == 4 then (
			clsName = tk[1]
			try (
				val = (execute clsName)
				sc = superClassOf val
				-- Alternative: check for .classID == #(-1,0)
				if sc==MAXWrapper or sc==node or sc==material or sc==MAXWrapperNonRefTarg then (
					append cls val
					format "%: %\n" c val
				) else (
					format "Skipping % (%)\n" val sc
				)
			) catch (
				format "Cannot use % for searching missing plugins.\n" clsName
			)
		) else (
			format "Incorrect string found in missing plugin name list: %\n" tk
		)
	)
	-- now search for instances of those missing plugins
	c = 0
	foundMissing = #()
	for j = 1 to cls.count do (
		cc = cls[j]
		ci = getClassInstances cc
		if ci.count > 0 then (
			format "%: Found % instances of %: %\n" j ci.count cc ci
			for i = 1 to ci.count do (
				-- get current class
				myClass = classOf cc
				append foundMissing myClass
				-- get list of all subclasses
				allClasses = myClass.classes
				for k = 1 to allClasses.count do (
					-- search for useful replacement
					if allClasses[k].creatable then (
						-- create new instance of default (first) class
						newInst = createInstance allClasses[k]
						try (
							-- replace all instances (requires 3ds Max 2008+ or AVG extensions)
							q = replaceInstances ci[i] newInst
							c += 1
							-- and exit for k loop
							exit
						) catch (
							format "Error replacing %\n" ci[i]
							format "Exception: %\n" (getCurrentException())
						)
					)
				) -- end: for k
				-- todo: what happens if NO useful replacement was found?
			) -- end: for i
		) -- end: if
	) -- end: for j
	if c > 0 then (
		-- produce summary message for user
		str = "Replaced "
		append str (c as string)
		append str " missing plugin(s) with default objects:\n"
		for i in foundMissing do (
			append str "\t"
			append str (i as string)
			append str "\n"
		)
		append str "\nUSE RESULT WITH CAUTION!\nSAVE TO A DIFFERENT FILE NAME!"
		messageBox str title:"removeMissingPlugins v0.1" beep:true
		print foundMissing
	) else (
		messageBox "No missing plugins found" title:"removeMissingPlugins v0.1"
	)
)
