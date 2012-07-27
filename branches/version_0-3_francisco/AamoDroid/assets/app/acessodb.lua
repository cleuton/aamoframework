-- local cursor = {}
cursor = aamo.query("consulta","select * from contato")

while aamo.eof("consulta") do
    aamo.log("entrou no while")
	for i=1,#cursor do
   		aamo.log(cursor[i])
	end

	cursor = aamo.next("consulta")
	aamo.log("chamou o next")
end


--close the cursor 
aamo.log("vai fechar o cursor consulta")
aamo.close("consulta")
aamo.log("fechou o cursor consulta")

-- cursor:moveToNext()
-- aamo.showMessage(cursor:getString(1))