-- pX SymmetryFix
-- Denys Almaral

-- Tries to fix the simmetry of Editable Poly for vertices not catched by "Symmetry Tools" using conextions instead of position.
/*
 Algorithm to implement:
 
 - Find symmetrical pairs of vertices.
 - Consider x=0 vertices as paired.
 - go for every non-paired vertices and link
 -- Store all edge conextions for each non-paired vertices.
 REPEAT PASSES
 - go for each non-paired Right-Side vertice
 -- Check its edge conections.
 -- Find a Left-Side vertice with same connections. 
 --- FOUND IF: Exist only one wieh same connections.
 --- Update connections.
 UNTIL CAN'T find more new pairs   
*/

struct TVertInfo  ( RightSide, LinkedTo, PairedWith ) --[ RightSide:boolean, LinkedTo, PairedWith ]
Tolerance = 0.005
MySelection = #{}

function FindPairs EPolyObj  = 
(
	local N = polyop.getNumVerts EPolyObj 
	local Result = #{}
	Result.count = N	
	
	UnPairedTag = N+99
	
	local VertsInfo = #() --array of TVertInfo
	VertsInfo.count = N
	
	--initializing vertInfo
	for i=1 to N do in coordsys local
	(
		local v1 = polyop.getVert EPolyObj i
		VertsInfo[i] = TVertInfo undefined undefined undefined
		VertsInfo[i].RightSide = ( v1.x >= 0 )
		
		--Vertices on the Symmetry AXE paired with themselves. 
		If 	abs(v1.x) <= Tolerance then 
		(	
			VertsInfo[i].PairedWith = i			
		)
		
		--Links
		--FindingEdge connections with other vertices
		local MyEdges = polyop.getEdgesUsingVert EPolyObj  i
		VertsInfo[i].Linkedto = #{}	
		for k in MyEdges do
		(
			VertsInfo[i].Linkedto  = VertsInfo[i].Linkedto  + (polyop.getVertsUsingEdge EPolyObj k )			
		)		
		VertsInfo[i].Linkedto =  VertsInfo[i].Linkedto - #{i}
	)
	
	for i=1 to N-1 do in coordsys local
	(
		local v1 = polyop.getVert EPolyObj i			
		
		
		--Finding first pairs by position	
		for j=(i+1) to N do
		(			
			v2 = polyop.getVert EPolyObj j
			v2.x = -v2.x
			d = (distance v1 v2)
			
			if d<=Tolerance then
			(
				VertsInfo[i].PairedWith = j
				VertsInfo[j].PairedWith = i				
			)	
		)
	)
	
	-- Find pairs by links -------------------------- the cool start here --------------
	
	
	
	do 
	(
		Local FoundNewPairs=0
		
		for i=1 to N do in coordsys local
		(		
			
			if VertsInfo[i].RightSide then
			(
				if VertsInfo[i].PairedWith==undefined then
				(
					Result[i] = true
					local MyCandidate = 0
					local MyCandidateNum = 0
					
					for j=1 to N-1 do
					(
						if i!=j then 
						(							
							local RSymLinks = #{}
							local RUnpairedLinks = 0
							local LSymLinks = #{}
							local LUnpairedLinks = 0
							--Remap the links using paired Vertice Numbers. 
							--Right
							for k in VertsInfo[i].LinkedTo do
							(
								if VertsInfo[k].PairedWith==undefined then
								(
									RUnpairedLinks +=  1
								) else 
								(
									if VertsInfo[k].RightSide then 
									(
										RSymLinks = RSymLinks + #{ k }
									) else
									(
										RSymLinks = RSymLinks + #{ VertsInfo[k].PairedWith }
									)
								)					
							)
							--left
							for k in VertsInfo[j].LinkedTo do
							(
								if VertsInfo[k].PairedWith==undefined then
								(
									LUnpairedLinks += 1
								) else 
								(
									if VertsInfo[k].RightSide then 
									(
										LSymLinks = LSymLinks + #{ k }
									) else
									(
										LSymLinks = LSymLinks + #{ VertsInfo[k].PairedWith } 
									)
								)					
							)
							
							-- And now the moment of "almost" truth!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
							-- The left vert qualify for pairing???
							
							--Empty links sets, cant prove nothing 
							if (not RSymLInks.isEmpty) and (not RSymLinks.isEmpty )then 
							(
								-- Testing if two SETS are EQUAL:
								if (RSymLinks-LSymLinks).isEmpty and (LSymLinks-RSymLinks).IsEmpty  then
								(
									--but wat about the Unpaired links?
									if RUnpairedLinks == LUnpairedLinks then
									(
										--this is a good candidate!
										--lets see if  there not already one before...
										if MyCandidate==0 then 
										(
											--Nice this is the first (hope only)
											MyCandidate=j 
											MyCandidateNum+= 1
											print ("Candidate! " + (MyCandidate as string) )
										) else
										(
											--no need for more searching there are duplicated "ideal" conditions
											--but instead of exiting the loops, lets just count the candidates
											MyCandidateNum += 1
										)
									)
								)
							)
						
						)
					)--For J end
					
					--if One and only One then yeah
					if MyCandidateNum == 1 then
					(
						--We can pair vert I with vert MyCandidate
						VertsInfo[i].PairedWith = MyCandidate
						--VertsInfo[MyCandidate].PairedWith = i
						FoundNewPairs += 1 
						print ("Pair:" + (i as string) + "-" + (MyCandidate as string) ) 
					)
					
				)
			)
		)--For I end
		print ("Found New Pairs: " + (FoundNewPairs	as string))
	)	while FoundNewPairs!=0
		
		
	Result
	
)


$.selectedVerts = FindPairs $