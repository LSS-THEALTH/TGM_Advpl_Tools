#Include 'Protheus.ch'

User Function TINFRPO()

	Local cFunc:= "CRMXPic*"
	Local aFile:= {}

	Local aRet
	Local nCount
	Local aType // Para retornar a origem da fun��o: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONE
	Local aFile // Para retornar o nome do arquivo onde foi declarada a fun��o
	Local aLine // Para retornar o n�mero da linha no arquivo onde foi declarada a fun��o
	Local aDate // Para retornar a data da �ltima modifica��o do c�digo fonte compilado
	Local aTime // Para retornar a hora da �ltima modifica��o do c�digo fonte compilado

	// Buscar informa��es de todas as fun��es contidas no APO
	aRet:= GetFuncArray(cFunc, @aType, @aFile, @aLine, @aDate, @aTime)

	If Len(aRet) > 0
		For nCount:= 1 To Len(aRet)
			Alert( "Funcao: " + aRet[nCount] ;
				+ ", Arquivo: " + aFile[nCount] ;
				+ ", Data: " + DtoC(aDate[nCount]) + " " + aTime[nCount] ;
				+ ", Linha: " + aLine[nCount] )
		Next nCount
	Else
		Alert("Nenhuma fun��o encontrada!")
	EndIf

Return

