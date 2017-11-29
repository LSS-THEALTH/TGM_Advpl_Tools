#INCLUDE 'TOTVS.ch'
#INCLUDE "Protheus.ch"
#INCLUDE "UPDCUSTOM.CH"

//====================================================================================================================\\
/*/{Protheus.doc}UPDCUSTOM
  ====================================================================================================================
	@description
	Classe utilizada para efetuar atualiza��es de dicion�rio customizadas
	Defini��o da classe

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

	@obs
	.

/*/
//===================================================================================================================\\
CLASS UPDCUSTOM

	DATA aSXFile
	DATA cTitulo

	METHOD New() CONSTRUCTOR
	METHOD AddProperty()
	METHOD RunUpdate()
	METHOD FSTProc()
	METHOD FSAtuFile()
	METHOD FsPosicFile()
	METHOD GetProperty()
	METHOD SetProperty()
	METHOD DefaultProp()
	METHOD AjustaSX3()
	METHOD AjustaSX6()

ENDCLASS
// FIM da Defini��o da Classe UPDCUSTOM
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}New
  ====================================================================================================================
	@description
	M�todo que criador da classe

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016
	@return		Objeto, Inst�ncia em da classe UPDCUSTOM

/*/
//====================================================================================================================\\
METHOD New(cTitulo) CLASS UPDCUSTOM

	Default cTitulo:= "Compatibilizador de campos de usu�rio"

	::cTitulo:= cTitulo
	::aSXFile:= {}

Return (SELF)
// FIM do m�todo New
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}AddProperty
  ====================================================================================================================
	@description
	Adiciona uma propriedade a um arquivo para atualizar

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

	@obs
	Formato da Propriedade: { "X2_CHAVE", "SC5" }

	Quando for somente atualiza��o, incluir a propriedade: { "UPDCUSTOM_SOUPDATE", .T. }

	Formato dos arquivos:
	SX2: "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
		"X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
		"X2_POSLGT" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }

	SX3: 

/*/
//====================================================================================================================\\
METHOD AddProperty(cSXFile, aPropAdic) CLASS UPDCUSTOM

	Local nX
	Local nPosSX:= aScan(::aSXFile, {|x| x[1] == cSXFile })
	Local aSxAtu

	If nPosSX == 0
		aAdd(::aSXFile, { cSXFile, {} })
		nPosSX:= Len(::aSXFile)
	EndIf

	aSxAtu:= ::aSXFile[nPosSX][2]
	aAdd( aSxAtu, {} )

	For nX:= 1 To Len(aPropAdic)
		aAdd( aTail(aSxAtu), {aPropAdic[nX,1], aPropAdic[nX,2]} )
	Next nX

Return (Nil)
// FIM do m�todo AddProperty
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}RunUpdate
  ====================================================================================================================
	@description
	Executa o compatibilizador

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016
	@return		Objeto, Inst�ncia em da classe UPDCUSTOM

/*/
//====================================================================================================================\\
METHOD RunUpdate(lAuto) CLASS UPDCUSTOM
	Local lOk:= .F.
	Local aMsg:= {}
	Local aButton:= {}
	Local aMarcadas:= {}

	Default lAuto:= .F.

	Private oMainWnd  := NIL
	Private oProcess  := NIL
	Private cDirComp  := NIL
	Private aSXFile   := ::aSXFile

	#IFDEF TOP
	    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On

	If lAuto
		lOk:= .T.
	Else
		// Mensagens de Tela Inicial
		aAdd( aMsg, "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema ( SX?/SIX )" )
		aAdd( aMsg, "Este processo deve ser executado em modo EXCLUSIVO." )

		// Botoes Tela Inicial
		aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
		aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

		FormBatch( ::cTitulo,  aMsg,  aButton )
	EndIf

	If lOk
		aMarcadas := EscEmpresa(lAuto)

		If !Empty( aMarcadas )

			If lAuto .Or. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", ::cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := ::FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lOk
					MsgStop( "Atualiza��o Conclu�da." )
				Else
					MsgStop( "Atualiza��o n�o Realizada." )
				EndIf

			Else
				MsgStop( "Atualiza��o n�o Realizada.", "COMPDIC" )

			EndIf

		Else
			MsgStop( "Atualiza��o n�o Realizada.", "COMPDIC" )

		EndIf

	EndIf

Return
// FIM do m�todo RunUpdate
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}FSTProc
  ====================================================================================================================
	@description
	Fun��o de processamento da grava��o dos arquivos
	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016
	@return		Objeto, Inst�ncia em da classe UPDCUSTOM
	
/*/
//====================================================================================================================\\
METHOD FSTProc( lEnd, aMarcadas, lAuto ) CLASS UPDCUSTOM

	Local aInfo     := {}
	Local aRecnoSM0 := {}
	Local cAux      := ""
	Local cFile     := ""
	Local cFileLog  := ""
	Local cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local cTCBuild  := "TCGetBuild"
	Local cTexto    := ""
	Local cTopBuild := ""
	Local lOpen     := .F.
	Local lRet      := .T.
	Local nPos      := 0
	Local nRecno    := 0
	Local oDlg      := NIL
	Local oFont     := NIL
	Local oMemo     := NIL
	Local nI        := 0
	Local nX        := 0
	Local nL        := 0

	Default lAuto:= .F.

	Private aArqUpd   := {}

	If ( lOpen := MyOpenSm0(.T.) )

		dbSelectArea( "SM0" )
		dbGoTop()

		While !SM0->( EOF() )
			// S� adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
			.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End

		SM0->( dbCloseArea() )

		If lOpen

			For nI := 1 To Len( aRecnoSM0 )

				If !( lOpen := MyOpenSm0(.F.) )
					MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora �nicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Vers�o.............: " + GetVersao(.T.) )
				AutoGrLog( " Usu�rio TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )

				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usu�rio da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Esta��o............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conex�o............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )

				oProcess:SetRegua1( Len(aSXFile) )

				For nL:= 1 To Len(aSXFile)

					oProcess:IncRegua1( "Atualizando arquivo " + aSXFile[nL][1] + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
					::FSAtuFile(aSXFile[nL][1], aSXFile[nL][2])

				Next nL

				If Len( aArqUpd ) > 0
					oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
					oProcess:SetRegua2( Len( aArqUpd ) )

					// Altera��o f�sica dos arquivos
					__SetX31Mode( .F. )

					If FindFunction(cTCBuild)
						cTopBuild := &cTCBuild.()
					EndIf

					For nX := 1 To Len( aArqUpd )

						oProcess:IncRegua2( "Sincronizando Arquivo " + aArqUpd[nX] + " com o banco de dados..." )

						If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
							If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
								!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
								TcInternal( 25, "CLOB" )
							EndIf
						EndIf

						If Select( aArqUpd[nX] ) > 0
							dbSelectArea( aArqUpd[nX] )
							dbCloseArea()
						EndIf

						X31UpdTable( aArqUpd[nX] )

						If __GetX31Error()
							Alert( __GetX31Trace() )
							AutoGrLog( "Ocorreu um erro desconhecido durante a atualiza��o da estrutura da tabela : " + aArqUpd[nX] )
							MsgStop( "Ocorreu um erro desconhecido durante a atualiza��o da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicion�rio e da tabela.", "ATEN��O" )
						EndIf

						If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
							TcInternal( 25, "OFF" )
						EndIf

					Next nX

				EndIf

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )

				RpcClearEnv()

			Next nI

			If .T. //!lAuto //TODO: Ajustar a condi��o

				cTexto := LeLog()

				Define Font oFont Name "Mono AS" Size 5, 12

				Define MsDialog oDlg Title "Atualiza��o concluida." From 3, 0 to 340, 417 Pixel

				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont

				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
				MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

				Activate MsDialog oDlg Center

			EndIf

		EndIf

	Else

		lRet := .F.

	EndIf

Return (lRet)
// FIM do m�todo FSTProc
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}FSAtuFile
  ====================================================================================================================
	@description
	Fun��o para grava��o dos arquivos do dicion�rio

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD FSAtuFile(cAliSX, aUpdates) CLASS UPDCUSTOM

	Local lAtu
	Local lInclui
	Local lOk
	Local cChave
	Local nPosField
	Local nL
	Local nX
	Local cAlias
	Local aRecOrd

	AutoGrLog( "�nicio da Atualiza��o do arquivo " + cAliSX + CRLF )

	oProcess:SetRegua2( Len( aUpdates ) )

	For nL := 1 To Len(aUpdates)
	
		oProcess:IncRegua2( "Atualizando arquivo " + cAliSX + "..." )

		lOk := .F.
		If ::FsPosicFile(cAliSX, aUpdates[nL], @cAlias, @cChave, @lInclui)

			RecLock(cAliSX,lInclui)
			For nX:= 1 To Len(aUpdates[nL])

				If ! "UPDCUSTOM_" $ aUpdates[nL][nX][1]

					nPosField:= (cAliSX)->(FieldPos(aUpdates[nL][nX][1]))

					If nPosField > 0
						lAtu := .F.

						If lInclui .Or. (cAliSX)->(FieldGet(nPosField)) <> aUpdates[nL][nX][2]
							
							lAtu:= .T.
							lOk:= .T.
							(cAliSX)->(FieldPut(nPosField , aUpdates[nL][nX][2]))

						EndIf

						If !lInclui // Mensagem modo verboso
							// AutoGrLog(' - Chave: ' + cChave + ' Propriedade: ' + aUpdates[nL][nX][1] + Iif(lAtu, '' , ' j�' ) + ' Atualizada' + CRLF )
						EndIf
					Else
						AutoGrLog(' - Chave: ' + cChave + ' Propriedade n�o encontrada: ' + aUpdates[nL][nX][1] + CRLF )
					EndIf

				EndIf

			Next nX

			If lOk
				AutoGrLog(' - Chave: ' + cChave + if(lInclui,' incluido',' alterado') + ' com sucesso!' + CRLF )
				If ! Empty(cAlias) .And. aScan(aArqUpd, {|x| x == cAlias }) == 0
					aAdd(aArqUpd, cAlias)
				EndIf
			EndIf

			(cAliSX)->(MsUnlock())


			// ========================================================
			// Ajusta Ordem do campo
			// ========================================================
			If ! Empty( ::GetProperty(aUpdates[nL], "UPDCUSTOM_X3REORDER") )
				aRecOrd:= ::GetProperty(aUpdates[nL], "UPDCUSTOM_X3REORDER")
				For nX:= 1 To Len(aRecOrd)
					SX3->(DbGoto(aRecOrd[nX][1]))
					RecLock("SX3",.F.)
					SX3->X3_ORDEM:= aRecOrd[nX][2]
					SX3->(MsUnlock())
				Next nX

			EndIf
			// ========================================================
			// Ajusta Ordem do campo - FIM
			// ========================================================

		EndIf
	
	Next nL

	AutoGrLog( CRLF + "Final da Atualiza��o do arquivo " + cAliSX + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL
// FIM da Fun��o FSAtuFile
//====================================================================================================================\\


//====================================================================================================================\\
/*/{Protheus.doc}FsPosicFile
  ====================================================================================================================
	@description
	Fun��o para grava��o dos arquivos do dicion�rio

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD FsPosicFile(cAliSX, aUpdate, cAlias, cChave, lInclui) CLASS UPDCUSTOM

	Local lRet:= .F.

	Do Case

		// ========================================================
		// Tratamento do SX3
		// ========================================================	
		Case (cAliSX == "SX3")
			dbSelectArea("SX3")
			DbSetOrder(2)
			cChave:= ::GetProperty(aUpdate, "X3_CAMPO")
			If ! Empty(cChave)
				lInclui:= ! DbSeek(cChave)
				If lInclui .And. ::GetProperty(aUpdate, "UPDCUSTOM_SOUPDATE")
					AutoGrLog( "ERRO: Campo " + cChave + " n�o existe no SX3." )
				Else
					lRet:= .T.
				EndIf

				If lRet

					// Determina o Alias do campo
					If ( At('_',cChave)==3 )
						cAlias:= "S" + Left(cChave,2)
					Else
						cAlias:= Left(cChave,3)
					EndIf

					::AjustaSX3(aUpdate, cAlias, cChave, lInclui)

				EndIf
			Else
				AutoGrLog( "ERRO: Propriedade 'Nome do campo' n�o identificada para atualiza��o do SX3." )
			EndIf
		// ========================================================
		// Tratamento do SX3 - FIM
		// ========================================================	


		// ========================================================
		// Tratamento do SX6
		// ========================================================	
		Case (cAliSX == "SX6")
			dbSelectArea("SX6")
			DbSetOrder(1)
			dbGoTop()

			::DefaultProp(aUpdate, "X6_FIL", Space(Len(SX6->X6_FIL)))

			cChave:= ::GetProperty(aUpdate, "X6_VAR")

			If ! Empty(cChave)
				
				cChave:= ::GetProperty(aUpdate, "X6_FIL") + cChave

				lInclui:= ! DbSeek(cChave)
				If lInclui .And. ::GetProperty(aUpdate, "UPDCUSTOM_SOUPDATE")
					AutoGrLog( "ERRO: Par�metro " + cChave + " n�o existe no SX6." )
				Else
					lRet:= .T.
				EndIf

				If lRet
					::AjustaSX6(aUpdate, cAlias, cChave, lInclui)
				EndIf
			Else
				AutoGrLog( "ERRO: Propriedade 'Nome do Par�metro (X6_VAR)' n�o identificada para atualiza��o do SX6." )
			EndIf
		// ========================================================
		// Tratamento do SX6 - FIM
		// ========================================================	


		// ========================================================
		// Tratamento do SX5
		// ========================================================	
		Case (cAliSX == "SX5")
			dbSelectArea("SX5")
			DbSetOrder(1)
			dbGoTop()

			::DefaultProp(aUpdate, "X5_FILIAL", Space(Len(SX5->X5_FILIAL)))

			If ! Empty( ::GetProperty(aUpdate, "X5_TABELA") )
				
				If ! Empty( ::GetProperty(aUpdate, "X5_CHAVE") )
					cChave:= ::GetProperty(aUpdate, "X5_FILIAL")
					cChave+= ::GetProperty(aUpdate, "X5_TABELA")
					cChave+= ::GetProperty(aUpdate, "X5_CHAVE")

					lInclui:= ! DbSeek(cChave)
					If lInclui .And. ::GetProperty(aUpdate, "UPDCUSTOM_SOUPDATE")
						AutoGrLog( "ERRO: Tabela/Chave " + cChave + " n�o existe no SX5." )
					Else
						If ! Empty( ::GetProperty(aUpdate, "X5_DESCRI") )
							lRet:= .T.
						Else
							AutoGrLog( "ERRO: Propriedade 'Descricao (X5_DESCRI)' n�o identificada para atualiza��o do SX5." )
						EndIf
					EndIf

					If lRet .And. lInclui
						::DefaultProp(aUpdate, "X5_DESCSPA", ::GetProperty(aUpdate, "X5_DESCRI"))
						::DefaultProp(aUpdate, "X5_DESCENG", ::GetProperty(aUpdate, "X5_DESCRI"))
					EndIf

				Else
					AutoGrLog( "ERRO: Propriedade 'CHAVE (X5_CHAVE)' n�o identificada para atualiza��o do SX5." )
				Endif

			Else
				AutoGrLog( "ERRO: Propriedade 'TABELA (X5_TABELA)' n�o identificada para atualiza��o do SX5." )
			EndIf
		// ========================================================
		// Tratamento do SX5 - FIM
		// ========================================================	


		Otherwise
			AutoGrLog( "Compatibilizador n�o implementado para tratar o arquivo " + cAliSX )

	EndCase

Return (lRet)
// FIM da Fun��o FsPosicFile
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}GetProperty
  ====================================================================================================================
	@description
	Fun��o para grava��o dos arquivos do dicion�rio

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD GetProperty(aProper, cProper) CLASS UPDCUSTOM

	Local xRet
	Local nPos

	nPos:= aScan(aProper, {|x| x[1] == cProper })

	If nPos > 0
		//  Se informar a Propriedade UPDCUSTOM_SOUPDATE n�o l�gica, considera verdadeiro.
		If cProper == "UPDCUSTOM_SOUPDATE" .And. ( Len(aProper[nPos]) < 2 .Or. ValType( aProper[nPos][2] ) != "L" )
			xRet:= .T.
		Else
			xRet:= aProper[nPos][2]
		EndIf
	EndIf

	// Padr�o para a propriedade UPDCUSTOM_SOUPDATE � .F.
	If cProper == "UPDCUSTOM_SOUPDATE" .And. ValType( xRet ) != "L"
		xRet:= .F.
	EndIf

Return (xRet)
// FIM da Fun��o GetProperty
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}SetProperty
  ====================================================================================================================
	@description
	Altera uma propriedade

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD SetProperty(aProper, cProper, xValue) CLASS UPDCUSTOM

	Local xRet
	Local nPos

	nPos:= aScan(aProper, {|x| x[1] == cProper })

	If nPos <= 0
		aAdd(aProper, {cProper, xValue})
	Else
		aProper[nPos][2]:= xValue
	EndIf

Return (Nil)
// FIM da Fun��o SetProperty
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}DefaultProp
  ====================================================================================================================
	@description
	Adiciona um valor padr�o para uma propriedade

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD DefaultProp(aUpdate, cProper, xValue) CLASS UPDCUSTOM

	If Empty( ::GetProperty(aUpdate, cProper) )
		aAdd(aUpdate, { cProper, xValue })
	EndIf

Return (Nil)
// FIM da Fun��o DefaultProp
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}AjustaSX6
  ====================================================================================================================
	@description
	Ajustes para inclus�o de campo no SX3

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD AjustaSX6(aUpdate, cAlias, cChave, lInclui) CLASS UPDCUSTOM

	Local cX6Descri
	Local nX6TamDes

	If lInclui
		::DefaultProp(aUpdate, "X6_TIPO", "C")
		::DefaultProp(aUpdate, "X6_PROPRI", "U")
		::DefaultProp(aUpdate, "X6_PYME", "S")
	EndIf

	::DefaultProp(aUpdate, "X6_DESCRIC", "")
	::DefaultProp(aUpdate, "X6_DESC1", "")
	::DefaultProp(aUpdate, "X6_DESC2", "")

	cX6Descri:= ::GetProperty(aUpdate, "X6_DESCRIC")
	cX6Descri+= ::GetProperty(aUpdate, "X6_DESC1")
	cX6Descri+= ::GetProperty(aUpdate, "X6_DESC2")
	nX6TamDes:= Len(SX6->X6_DESCRIC)

	If Len(cX6Descri) > nX6TamDes
		::SetProperty(aUpdate, "X6_DESCRIC", Substr(cX6Descri, 1, nX6TamDes))

		cX6Descri:= Substr(cX6Descri, nX6TamDes+1)
		nX6TamDes:= Len(SX6->X6_DESC1)
		::SetProperty(aUpdate, "X6_DESC1", Substr(cX6Descri, 1, nX6TamDes))

		If Len(cX6Descri) > nX6TamDes
			cX6Descri:= Substr(cX6Descri, nX6TamDes+1)
			nX6TamDes:= Len(SX6->X6_DESC2)
			::SetProperty(aUpdate, "X6_DESC2", Substr(cX6Descri, 1, nX6TamDes))
		EndIf

	EndIf

	::DefaultProp(aUpdate, "X6_DSCSPA", ::GetProperty(aUpdate, "X6_DESCRIC"))
	::DefaultProp(aUpdate, "X6_DSCENG", ::GetProperty(aUpdate, "X6_DESCRIC"))
	::DefaultProp(aUpdate, "X6_DSCSPA1", ::GetProperty(aUpdate, "X6_DESC1"))
	::DefaultProp(aUpdate, "X6_DSCENG1", ::GetProperty(aUpdate, "X6_DESC1"))
	::DefaultProp(aUpdate, "X6_DSCSPA2", ::GetProperty(aUpdate, "X6_DESC2"))
	::DefaultProp(aUpdate, "X6_DSCENG2", ::GetProperty(aUpdate, "X6_DESC2"))

	If ! Empty( ::GetProperty(aUpdate, "X6_CONTEUD") )
		::DefaultProp(aUpdate, "X6_CONTSPA", ::GetProperty(aUpdate, "X6_CONTEUD"))
		::DefaultProp(aUpdate, "X6_CONTENG", ::GetProperty(aUpdate, "X6_CONTEUD"))
	EndIf

Return (Nil)
// FIM da Fun��o AjustaSX6
//====================================================================================================================\\



//====================================================================================================================\\
/*/{Protheus.doc}AjustaSX3
  ====================================================================================================================
	@description
	Ajustes para inclus�o de campo no SX3

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		01/12/2016

/*/
//====================================================================================================================\\
METHOD AjustaSX3(aUpdate, cAlias, cChave, lInclui) CLASS UPDCUSTOM

	Local nRecno
	Local aRecOrd
	Local cOrdem
	Local nOrdem
	Local nOrdX3Atu

	// ========================================================
	// Ajustes para inclus�o de campo SX3
	// ========================================================
	If lInclui
		::DefaultProp(aUpdate, "X3_ARQUIVO", cAlias)
		::DefaultProp(aUpdate, "X3_PROPRI", "U")
		::DefaultProp(aUpdate, "X3_VISUAL", "A")
		::DefaultProp(aUpdate, "X3_CONTEXT", "R")
		::DefaultProp(aUpdate, "X3_PYME", "S")
		::DefaultProp(aUpdate, "X3_TITSPA", ::GetProperty(aUpdate, "X3_TITULO"))
		::DefaultProp(aUpdate, "X3_TITENG", ::GetProperty(aUpdate, "X3_TITULO"))
		::DefaultProp(aUpdate, "X3_DESCSPA", ::GetProperty(aUpdate, "X3_DESCRIC"))
		::DefaultProp(aUpdate, "X3_DESCENG", ::GetProperty(aUpdate, "X3_DESCRIC"))
		::DefaultProp(aUpdate, "X3_USADO", "���������������")
		::DefaultProp(aUpdate, "X3_NIVEL", 1)
		::DefaultProp(aUpdate, "X3_RESERV", "��")
		::DefaultProp(aUpdate, "X3_ORTOGRA", "N")
		::DefaultProp(aUpdate, "X3_IDXFLD", "N")

	EndIf	
	// ========================================================
	// Ajustes para inclus�o de campo SX3 - FIM
	// ========================================================

	// ========================================================
	// Ajusta Ordem do campo
	// ========================================================
	nRecno:= If(lInclui, 0, Recno())
	cOrdem:= ::GetProperty(aUpdate, "X3_ORDEM")
	aRecOrd:= {}

	If Empty(cOrdem)
		cOrdem:= "ZZ"
	EndIf

	If Len(cOrdem) == 2
		nOrdem:= Val(RetAsc(cOrdem,3,.F.))
	Else
		nOrdem:= Val(cOrdem)
	EndIf

	cOrdem:= RetAsc(nOrdem,2,.T.)

	DbSetOrder(1)
	DbSeek(cAlias + cOrdem, .T.) 
	
	If cAlias != X3_ARQUIVO
		dbSkip(-1)
	EndIf

	If cAlias == X3_ARQUIVO
		nOrdX3Atu:= Val(RetAsc(SX3->X3_ORDEM,3,.F.))
		If ( nOrdem > nOrdX3Atu )
			nOrdem:= nOrdX3Atu + 1
		ElseIf nOrdem == nOrdX3Atu
			// Reordena os pr�ximos SX3
			SX3->(dbGoTop())
			DbSeek(cAlias)
			nOrdX3Atu:= 0
			While !Eof() .And. X3_ARQUIVO == cAlias
				If AllTrim(X3_CAMPO) != AllTrim(cChave)
					nOrdX3Atu++
					If nOrdX3Atu == nOrdem
						nOrdX3Atu++
					EndIf
					aAdd(aRecOrd, { Recno(), RetAsc(nOrdX3Atu,2,.T.)})
				EndIf
				dbSkip()
			EndDo
		EndIf

		If nOrdem <= 0
			nOrdem:= 1
		EndIf
	Else
		nOrdem:= 1
	EndIf

	aAdd(aUpdate, { "X3_ORDEM", RetAsc(nOrdem,2,.T.) })

	If Len(aRecOrd) > 0
		aAdd(aUpdate, { "UPDCUSTOM_X3REORDER", aRecOrd })
	EndIf

	DbSetOrder(2)
	If nRecno != 0
		dbGoTo(nRecno)
	EndIf

	// ========================================================
	// Ajusta Ordem do campo - FIM
	// ========================================================	

Return (Nil)
// FIM da Fun��o AjustaSX3
//====================================================================================================================\\



