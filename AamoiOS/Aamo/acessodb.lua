-- open database
aamo.openDatabase("contatos")

-- executa a query
cursor = aamo.query("consulta","select * from contato")

-- for i=1,#cursor do   
--	aamo.log(cursor[i])
-- end

-- percorre os registros retornados
while not aamo.eof("consulta") do
    -- imprime os campos do cursor
    for i=1,#cursor do   
   		aamo.log(cursor[i])
	end

	cursor = aamo.next("consulta")
	
end

-- close the cursor 
aamo.log("vai fechar o cursor consulta")
aamo.closeCursor("consulta")
aamo.log("fechou o cursor consulta")

-- close de database
aamo.closeDatabase("consulta")
aamo.log("fechou o banco de dados")