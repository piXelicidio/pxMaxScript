-- ISOLATED TEST for Edit_Poly Modifier Vertex Get / Set
-- Open a new scene, create a Box, and run this script.

(
    obj = $
    
    select obj
	epMod = obj.Modifiers[#Edit_poly]

    
    -- ==========================================
    -- READING VERTICES
    -- ==========================================
    
    -- Edit_Poly has a native GetVertex method. 
    -- Important: Using node:obj ensures it returns world coordinates. Or omit for local.
    local vIndex = 1
    local vPos = epMod.GetVertex vIndex node:obj
    format "Original Position of Vertex %: %\n" vIndex vPos

    -- ==========================================
    -- WRITING VERTICES 
    -- ==========================================
    
    -- The Edit_Poly modifier interface exposes a SetVert method which
    -- accepts a bitarray of indices and a Point3 value
    
    local targetPos = [10, 10, 10] 
    
    -- Set the vertex position
    epMod.SetVert #{vIndex} targetPos
    
    -- Important: Commit changes to push them to the modifier's internal stack delta
    epMod.Commit()

    -- Verify the new position
    local newVPos = epMod.GetVertex vIndex node:obj
    format "New Position of Vertex %: %\n" vIndex newVPos
    
   --// clearSelection()
)
