(
	/*
		Learn MaxScript in 5 Minutes
		Runnable directly in the 3ds Max Listener or Editor.
	*/

	/* 1. Variables and Data Types 
	*/
	/* MaxScript is dynamically typed. Use 'local' or 'global' to define scope. */
	local myInt = 42
	local myFloat = 3.14
	local myString = "Hello 3ds Max"
	local myBool = true

	/* Arrays are 1-indexed in MaxScript */
	local myArray = #(1, 2, 3, "four", 5.0)
	local firstItem = myArray[1] /* Returns 1 */
	append myArray 6 /* Adds 6 to the end */

	/* BitArrays are heavily used for vertex, edge, and face selections */
	local myBitArray = #{1..5, 10}

	/* Point3 objects are used for coordinates, vectors, and RGB colors */
	local myPos = [10, 20, 30]
	local myColor = color 255 128 0

	/* 2. Control Structures 
	*/
	if myInt > 40 then (
		print "Greater than 40"
	) else (
		print "Less or equal"
	)

	/* For loops */
	for i = 1 to 3 do (
		print i
	)

	/* Iterate directly over arrays or collections */
	for item in myArray do (
		print item
	)

	/* While loops */
	local count = 0
	while count < 3 do (
		count += 1
	)

	/* Case statements for pattern matching */
	case myInt of (
		42: print "The exact answer"
		default: print "Unknown value"
	)

	/* 3. Functions 
	*/
	/* Use 'fn' to declare a function. The last evaluated expression is returned. */
	fn addNumbers a b = (
		a + b
	)
	local sumResult = addNumbers 10 5

	/* Functions can use optional keyword arguments */
	fn createCustomBox name:"MyBox" size:10 = (
		box name:name length:size width:size height:size
	)
	createCustomBox size:20 /* Name defaults to "MyBox" */

	/* 4. Structs (Custom Objects) 
	*/
	/* Structs group variables and functions together */
	struct VectorMath (
		description = "Math utilities",
		
		fn addVectors v1 v2 = (
			v1 + v2
		)
	)
	local mathTools = VectorMath()
	local newVector = mathTools.addVectors [1,1,1] [2,2,2]

	/* 5. Scene Manipulation 
	*/
	/* Creating geometry */
	local mySphere = sphere radius:15 pos:[0, 0, 50]

	/* Modifying properties natively */
	mySphere.name = "MagicSphere"
	mySphere.segs = 32

	/* Modifiers */
	local myBend = bend angle:45
	addModifier mySphere myBend

	/* Selection and Transforms */
	select mySphere
	move $ [10, 0, 0] /* '$' references the current selection */

	/* 6. Rollouts (User Interfaces) 
	*/
	/* Rollouts define custom UI panels for tools */
	rollout myRollout "Tool Window" width:160 height:100 (
		button btn_doSomething "Click Me" pos:[10,10] width:140 height:30
		
		/* Event handlers map to UI elements */
		on btn_doSomething pressed do (
			messageBox "Script executed successfully!" title:"Alert"
		)
	)

	/* This command launches the rollout defined above */
	createDialog myRollout
)