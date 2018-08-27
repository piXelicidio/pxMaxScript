macroScript QuickRename category:"HowTo" 
(
	rollout rename_rollout "Enter New Base Name"
 (

  edittext base_name "" 
  button rename_them "RENAME SELECTED OBJECTS..." 
  on rename_them pressed do
  (
   if base_name.text != "" do
    for i in selection do i.name = uniquename base_name.text
  )--end on
 )--end rollout
 
createDialog rename_rollout 250 50
)
