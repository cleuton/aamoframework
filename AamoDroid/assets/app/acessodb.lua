local cursor = {}
cursor = aamo.query("select * from contato")

aamo.showMessage(cursor:getString(1))
cursor:moveToNext()
aamo.showMessage(cursor:getString(1))
cursor:moveToNext()
aamo.showMessage(cursor:getString(1))
cursor:moveToNext()
-- aamo.showMessage(cursor:isAfterLast())