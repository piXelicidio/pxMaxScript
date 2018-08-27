function DelphiExecute s = 
(
		res = Execute s
		return ((res as string) + " " +  (classof(res) as string))
)	

registerOLEInterface #(DelphiExecute)
