#Include 'protheus.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} AdvplClassTestExample
Classe de testes | Exemplo

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Class AdvplClassTestExample From FWDefaultTestCase
	Method AdvplClassTestExample()

    //M�todos especias
    Method SetUp()
    Method SetUpClass()
    Method TearDown()
    Method TearDownClass()

    //M�todos de teste
	Method MTrue()
    Method MFalse()
    Method MEqual()
    Method MNotEqual()
    Method MError()
    Method MSkip()
EndClass

//-------------------------------------------------------------------
/*/{Protheus.doc} AdvplClassTestExample
M�todo de inst�ncia da classe de testes

Obs.: O m�todo de inst�ncia deve ter o mesmo nome da classe!
	
@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method AdvplClassTestExample() Class AdvplClassTestExample
    //Adi��o dos m�todos default
	_Super:FWDefaultTestCase()

    //Adi��o dos m�todos de teste
	Self:AddTestMethod( "MTrue"     ,, "AssertTrue"     )
    Self:AddTestMethod( "MFalse"    ,, "AssertFalse"    )
    Self:AddTestMethod( "MEqual"    ,, "AssertEqual"    )
    Self:AddTestMethod( "MNotEqual" ,, "AssertNotEqual" )
    Self:AddTestMethod( "MSkip"     ,, "Skip"           )

    //Adi��o de m�todo de teste que espera um error.log
    Self:AddTestMethod( "MError" , .T. , "AssertNotEquals" )
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetUp
M�todo que � chamado antes de cada teste, podendo ser chamado N vezes

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method SetUp() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} SetUpClass
M�todo que � chamado antes de inicializar os testes da Classe,
sendo assim esse m�todo � chamado somente uma vez

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method SetUpClass() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} TearDown
M�todo que � chamado ap�s cada teste, podendo ser chamado N vezes

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method TearDown() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} TearDownClass
M�todo que � chamado ap�s a finaliza��o dos testes da Classe,
sendo assim esse m�todo � chamado somente uma vez

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method TearDownClass() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MTrue
M�todo que de teste que utilizada de resultado positivo ( .T. )

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MTrue() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()
oResult:AssertTrue( .T. )

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MFalse
M�todo que de teste que utilizada de resultado negativo ( .F. )

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MFalse() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

oResult:AssertFalse( .F. )

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MEqual
M�todo que de teste que utilizada de igualdade

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MEqual() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

oResult:AssertEqual( 'X' , 'X' )

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MNotEqual
M�todo que de teste que utilizada de diferen�a

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MNotEqual() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

oResult:AssertNotEqual( 'X' , 'T' )

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MSkip
M�todo que de teste que deixa de ser executado

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MSkip() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

oResult:Skip()

Return oResult

//-------------------------------------------------------------------
/*/{Protheus.doc} MError
M�todo que de teste que utilizada de error.log (Exce��o)

@author Daniel Mendes
@since Jul 31, 2018
@version 12
/*/
//-------------------------------------------------------------------
Method MError() Class AdvplClassTestExample
Local oResult As Object

oResult := FWTestResult():FWTestResult()

//Gero algum error.log

If aNotExists[0] == aExistsNot
EndIf

If lNotFound == 9
EndIf

If 'AAAAA' == 8
EndIf

Return oResult