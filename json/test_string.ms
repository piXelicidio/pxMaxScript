(
		
	function check_string s =
	(
		result = ""
		if s[1] == "\"" then 
		(
			local count = 1 
			done = false
			while not done do
			(
				count += 1
				local c = s[count]
				
				case of
				(
				   (c == "\"") : done = true
				   (c == "\\"): 
					(		
						result = result +c
						count +=1
						local cc = s[count]
						if (findString "\"\\\/bfnrt" cc) != undefined then
						(
							result = result + cc
						) else if cc == "u" then
							(
								result = result + cc
								for i=1 to 4 do
								(
									count = count + 1
									cc = s[count]
									if (findString "01234567890abcdef" cc)!= undefined then
									(
										result = result + cc
									) else
									(
										print "Hex code error"
										done = true
										exit
									)
								)
							) else 
							(
								print "String error: Unknown control code after \\"
							)
					)
				   ((findString "\n\\\t\r" c)==undefined): result = result + c
					default: (print "String error"; done = true )
				)
				if count>= s.count then done = true
			)
			return result
		) else 
	   (
		   print "expected \""
		   return undefined
	   )
	)
	
	check_string ("\""+@"denys y \uFFFF la amenaza"+"\"")
	
)