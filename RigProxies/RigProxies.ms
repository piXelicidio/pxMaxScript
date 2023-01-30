--RigProxies 
--Creates proxies of your rigs. Save the original in an scene proxy.
--Keep an optimized snapshot on the current scene.

--by Denys Almaral

function DefineAndRun = 
(
	local macroID = macroscript RigProxy category:"pX Tools" 
	(
		struct RigSnapshot
		(	
			
			isOk_func = undefined,
			
			function isOk_MeshOnly o =
			(
				(isKindOf o GeometryClass) and not ((classof o == Biped_Object) or (o.renderable == false))
			),
			
			function AddTree dest O = 
			(		
				if isOk_func(o) then appendIfUnique dest O
				
				for i=1 to  O.children.count do
				(
					AddTree dest O.children[i]
				)
				
				deps = refs.dependentNodes O
				for i=1 to deps.count do
				(
					if isOk_func(deps[i]) then appendIfUnique dest deps[i];			
					
				)
			),
			
			function ScanTree FromObj MeshOnly:true =
			(
				local objs = #()
				if MeshOnly then 
				( isOk_func = isOk_MeshOnly) 
				else 
				( isOk_func = fn isOk_all o = (true) )
					
				AddTree objs FromObj 
				--for o in objs do print o.name
				--return
				(objs)
			),
			
			function snap Root trans:[0,0,0] keepNames:false centerPivot:true =
			(
				local objs = ScanTree Root
				local cRoot = copy Root
				if keepNames then cRoot.name = Root.name
				local rootIdx = (findItem objs Root)
				if rootIdx!=0 then deleteItem objs rootIdx
				for obj in objs do 
				(
					local s = snapshot obj
					if keepNames then s.name = obj.name
					if centerPivot then s.pivot = s.center	
					s.parent = cRoot			
				)
				move cRoot trans
				--return
				cRoot
			)
		)
		
		local rigSnapper = RigSnapshot();
		local window = undefined;
		local RIG_PROXIES_DIR = ".rigproxies"
		local RIG_PROXY_FILE_PROP = "rigProxyFile"
		
		rollout RigProxy "RigProxy"
		(	
			local backToScene = undefined;
				
			group ""
			(
			button btnSnapAndProxy "Create RigProxy" tooltip:"Creates a Snapshot Proxy of rig starting at selected root obj. Saving the original rig in separated file."
			button btnUpdateFromProxy "Update RigProxy" tooltip:"Updates existing Snapshot from saved Proxy file bringing new modifications."			
			button btnUpdateAll "Update All RigProxies" tooltip:"not implemented" enabled:false
			button btnSnap "Simple Snapshot" tooltip:"Creates a Snapshot of rig starting at selected root. Does not save scene proxy, or delete original objects."
			button btnBringBack "Bring back original rig" tooltip:"Delete the snapshot and bring back the original rig" enabled:false
			button btnEditProxy "Edit Proxy scene..." tooltip:"Edit original rig proxy scene file"
				
			label lblProgress ""
			)			
			group "Updating settings:"
			(
			checkbox chkKeepMaterial "Keep Materials" checked:true tooltip:"Keep current material modifications"
			checkbox chkKeepRootTransform "Keep Root transform" checked:true tooltip:"Keep current root scale/position/rotation"
			)
			
			function getProxyDir =
			(
				makeDir (maxFilePath+RIG_PROXIES_DIR)
				--return
				(maxFilePath+RIG_PROXIES_DIR+"\\")
			)
			
			function onSelectionChanged =
			(
				if (backToScene == undefined) then
				(
					if (iskindof $ node) then
					( 
						local prop = (getUserProp $ RIG_PROXY_FILE_PROP) 
						btnSnapAndProxy.enabled = prop == undefined;
						btnSnap.enabled = true;
						btnUpdateFromProxy.enabled = prop != undefined; 
						btnEditProxy.enabled = prop != undefined;
						btnBringBack.enabled = prop != undefined;
						
					) else
					(
						btnSnapAndProxy.enabled = false;
						btnSnap.enabled = false;
						btnUpdateFromProxy.enabled = false;
						btnEditProxy.enabled = false;
						btnBringBack.enabled = false;
					)
				)
			)
			
			-- events
			
			on RigProxy open do
			(
				onSelectionChanged()
				callbacks.addScript #selectionSetChanged onSelectionChanged id:#snapProxies
			)
			
			on RigProxy close do
			(				
				callbacks.removeScripts #selectionSetChanged id:#snapProxies
			)
			
			on btnSnap pressed do
			(
				local newRoot = rigSnapper.snap $ trans:[100,0,0] keepNames:true
				select newRoot
			)
			
			on btnSnapAndProxy pressed do
			(	
				--TODO: validate $selection, single object, what if already a proxy
				local oldRoot = $
				local sroot = rigSnapper.snap oldRoot keepNames:true
				local objs = rigSnapper.ScanTree oldRoot MeshOnly:false 				
				select objs
				--TODO: fix names before using it for saving as .max (remove ilegal filename chars)
				local proxyfile = oldRoot.name+".max"
				saveNodes objs (getProxyDir() + proxyfile) quite:true
				setUserProp sroot RIG_PROXY_FILE_PROP proxyfile
				delete objs 
			)
			
			on btnUpdateFromProxy pressed do 
			(
				--TODO: validate $
				lblProgress.caption = "Working..."
				local old = $
				local proxyfile = getUserProp old RIG_PROXY_FILE_PROP
				if proxyfile != undefined then
				(
					local merged = undefined 					
					local isOk = mergeMaxFile (getProxyDir() + proxyfile) #mergeDups #useSceneMtlDups #neverReparent quiet:true mergedNodes:&merged
					local mergedRoot = undefined					
					if isOk then 
					(
						--looking for the merged root by name
						for i=1 to merged.count do
						(
							--print merged[i].name
							if merged[i].name == old.name then
							(
								mergedRoot = merged[i]								
								break;
							)
						)				
						if mergedRoot != undefined then 
						(
							--Saving current modifications:-----------------------------------
							local oldTransform = old.transform 
							local oldParent = old.parent
							local Mats = dictionary #string
							for o in old.children do 
							(
								Mats[o.name] = o.material
							)
							
							--Deleting current:
							delete old.children
							delete old 
							old = undefined;
							
							--Snapshoting just-merged and deleting all rig -----------------------
							local newRoot = rigSnapper.snap mergedRoot keepNames:true
							delete merged 
							--local objs = rigSnapper.ScanTree mergedRoot MeshOnly:false
							--delete objs
							
							--Applying saved modifications 
							setUserProp newRoot RIG_PROXY_FILE_PROP proxyfile
							if chkKeepRootTransform.checked then 
							(
								newRoot.transform = oldTransform
								newRoot.parent = oldParent
							)
							if chkKeepMaterial.checked then
							(
								for o in newRoot.children do 
								(
									o.material = Mats[o.name];
									if o.material == undefined then print ("Can't find material for " + o.name)										
								)
							)
							select newRoot
							--TODO: Manually reparent root if parent was present, investigate other kind of linkss
						) else print "Can't find proxy root on merged file"
					) else print "Can't Merge proxy file"
				) else print "Can't Proxy file linked."
				lblProgress.caption = "";
			)
			
			on btnBringBack pressed do 
			(
				--TODO: validate $
				lblProgress.caption = "Working..."
				local old = $
				local proxyfile = getUserProp old RIG_PROXY_FILE_PROP
				if proxyfile != undefined then
				(
					local merged = undefined 					
					local isOk = mergeMaxFile (getProxyDir() + proxyfile) #mergeDups #useSceneMtlDups #neverReparent quiet:true mergedNodes:&merged
					local mergedRoot = undefined					
					if isOk then 
					(
						--looking for the merged root by name
						for i=1 to merged.count do
						(
							--print merged[i].name
							if merged[i].name == old.name then
							(
								mergedRoot = merged[i]								
								break;
							)
						)				
						if mergedRoot != undefined then 
						(
							--Saving current modifications:-----------------------------------
							local oldTransform = old.transform 
							local oldParent = old.parent
							local Mats = dictionary #string
 							for o in old.children do 
 							(
 								Mats[o.name] = o.material
 							)
							
							--Deleting current:
							delete old.children
							delete old 
							old = undefined;							
														
							local newRoot = mergedRoot -- +
							
							--Applying saved modifications 							
							if chkKeepRootTransform.checked then 
							(
								newRoot.transform = oldTransform
								newRoot.parent = oldParent
							)
							if chkKeepMaterial.checked then
							(
								for o in merged do 
								(
									local savedMat = Mats[o.name];
									if savedMat != undefined then 
									(
										o.material = savedMat
									)
								)
							)
							select newRoot
							--TODO: Manually reparent root if parent was present, investigate other kind of linkss
						) else print "Can't find proxy root on merged file"
					) else print "Can't Merge proxy file"
				) else print "Can't Proxy file linked."
				lblProgress.caption = "";
			)
			
			on btnEditProxy pressed do
			(
				if (backToScene == undefined ) then
				(
					local isOk = (iskindof $ node)				
					local proxyFile = undefined;
					if isOk then 
					(
						local rootObj = $
						local proxyfile = getUserProp rootObj RIG_PROXY_FILE_PROP	
						if proxyfile != undefined then
						(
							proxyFile = getProxyDir() + proxyfile
							if (doesFileExist proxyfile)  then 
							(
								isOk = true;							
							) else print ("Proxy not found: "+ proxyfile)
						)
					)
					if isOk then
					(
						if checkForSave() then
						(
							if getSaveRequired() then
							(
								messageBox "RigProxies can't be edited without saving current scene!" icon:#warning						
							) else 
							(
								backToScene = maxFilePath + maxFileName
								local loaded = loadMaxFile proxyFile 
								if loaded then
								(
									btnSnapAndProxy.enabled = false;
									btnSnap.enabled = false;
									btnUpdateFromProxy.enabled = false;
									btnEditProxy.enabled = true;
									btnEditProxy.caption = "BACK TO MAIN SCENE"
								) else 
								(
									print ("Can't open proxyfile: "+proxyfile)
									backToScene = undefined;
								)
							)
						)
					)
				) else
				(
					--this means we are currently editing a proxy so we are going back to main scene
					if checkForSave() then
					(						
						if (loadMaxFile backToScene) then 
						(
							backToScene = undefined
							btnEditProxy.caption = "Edit Proxy scene...";
							onSelectionChanged();
						) else 
						(
							Print ("Can't load scene: " + backToscene)
						)
					)
				)
			)
		)
		
		on execute do
		(
			--window = newRolloutFloater "RigProxy" 300 300
			--addRollout RigProxy window 
			CreateDialog RigProxy 200 300
		)
	)
	macros.run macroID 
)
DefineAndRun()

