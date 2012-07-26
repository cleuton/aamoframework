-- local cursor = {}
cursor = aamo.query("select * from contato")

for i=1,#cursor do
   aamo.log(cursor[i])
end

-- next element
cursor = aamo.next()

--while ~ aamo.eof  --("contatos")
for i=1,#cursor do
   aamo.log(cursor[i])
end

--close the cursor 
aamo.close()

-- cursor:moveToNext()
-- aamo.showMessage(cursor:getString(1))