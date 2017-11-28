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

	Quando for somente atualiza��o, incluir a propriedade: { "SOMENTE_UPDATE", .T. }

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
METHOD RunUpdate() CLASS UPDCUSTOM
	Local lOk:= .F.
	Local aMsg:= {}
	Local aButton:= {}
	Local aMarcadas:= {}

	Private oMainWnd  := NIL
	Private oProcess  := NIL
	Private cDirComp  := NIL

	#IFDEF TOP
	    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On

	// Mensagens de Tela Inicial
	aAdd( aMsg, "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema ( SX?/SIX )" )
	aAdd( aMsg, "Este processo deve ser executado em modo EXCLUSIVO." )

	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

	FormBatch( ::cTitulo,  aMsg,  aButton )

	If lOk
		aMarcadas := EscEmpresa()

		If !Empty( aMarcadas )

			If MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", ::cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := ::FSTProc( @lEnd, aMarcadas ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lOk
					Final( "Atualiza��o Conclu�da." )
				Else
					Final( "Atualiza��o n�o Realizada." )
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

				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf

				oProcess:SetRegua1( Len(::aSXFile) )

				For nL:= 1 To Len(::aSXFile)

					oProcess:IncRegua1( "Atualizando arquivo " + ::aSXFile[nL][1] + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )

					FSAtuFile(::aSXFile[nL][1], ::aSXFile[nL][2])

				Next nL

				If Len( aArqUpd ) > 0
					oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
					oProcess:SetRegua2( "Atualizando campos/�ndices" )

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

			If !lAuto

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
Static Function FSAtuFile(cAliSX, aUpdates)

	Local lAtu
	Local lInclui
	Local lOk
	Local cChave
	Local nPosField
	Local nL
	Local nX
	Local cAlias

	AutoGrLog( "�nicio da Atualiza��o " + cAliSX + CRLF )

	oProcess:SetRegua2( Len( aUpdates ) )

	For nL := 1 To Len(aUpdates)
	
		oProcess:IncRegua2( "Atualizando arquivo " + cAliSX + "..." )

		lOk := .F.
		If FsPosicFile(cAliSX, aUpdates[nL], @cAlias, @cChave, @lInclui)

			RecLock(cAliSX,lInclui)
			For nX:= 1 To Len(aUpdates[nL])

				If ! aUpdates[nL][nX][1] == "SOMENTE_UPDATE"

					nPosField:= (cAliSX)->(FieldPos(aUpdates[nL][nX][1]))

					If nPosField > 0
						lAtu := .F.

						If lInclui .Or. (cAliSX)->(FieldGet(nPosField)) <> aUpdates[nL][nX][2]
							
							lAtu:= .T.
							lOk:= .T.
							(cAliSX)->(FieldPut(nPosField , aUpdates[nL][nX][2]))

						EndIf

						If !lInclui
							AutoGrLog(cAliSX + ' - Chave: ' + cChave + ' Propriedade: ' + aUpdates[nL][nX][1] + Iif(lAtu, '' , ' j�' ) + ' Atualizada' + CRLF )
						EndIf
					Else
						AutoGrLog(cAliSX + ' - Chave: ' + cChave + ' Propriedade n�o encontrada: ' + aUpdates[nL][nX][1] + CRLF )
					EndIf

				EndIf

			Next nX

			If lOk
				AutoGrLog(cAliSX + ' - Chave: ' + cChave + if(lInclui,'incluido','alterado') + ' com sucesso!' + CRLF )
				If ! Empty(cAlias) .And. aScan(aArqUpd, {|x| x == cAlias }) == 0
					//aAdd(aArqUpd, cAlias)
				EndIf
			EndIf

			(cAliSX)->(MsUnlock())

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
Static Function FsPosicFile(cAliSX, aUpdate, cAlias, cChave, lInclui)

	Local lRet:= .F.

	Do Case
		Case (cAliSX == "SX3")
			dbSelectArea("SX3")
			DbSetOrder(2)
			cChave:= GetProperty(aUpdate, "X3_CAMPO")
			If ! Empty(cChave)
				lInclui:= DbSeek(cChave)
				If lInclui .And. GetProperty(aUpdate, "SOMENTE_UPDATE")
					AutoGrLog( "ERRO: Campo " + cChave + " n�o existe no SX3." )
				EndIf

				// Determina o Alias do campo
				If ( At('_',cChave)==3 )
					cAlias:= "S" + Left(cChave,2)
				Else
					cAlias:= Left(cChave,3)
				EndIf

				// ========================================================
				// Ajustes para inclus�o de campo SX3
				// ========================================================

				If lInclui .And. Empty( GetProperty(aUpdate, "X3_ARQUIVO") )
					aAdd(aUpdate, { "X3_ARQUIVO", cAlias })
				EndIf

				If lInclui .And. Empty( GetProperty(aUpdate, "X3_PROPRI") )
					aAdd(aUpdate, { "X3_PROPRI", "U" })
				EndIf

				If lInclui .And. Empty( GetProperty(aUpdate, "X3_VISUAL") )
					aAdd(aUpdate, { "X3_VISUAL", "A" })
				EndIf

				If lInclui .And. Empty( GetProperty(aUpdate, "X3_CONTEXT") )
					aAdd(aUpdate, { "X3_CONTEXT", "R" })
				EndIf

				If lInclui .And. Empty( GetProperty(aUpdate, "X3_PYME") )
					aAdd(aUpdate, { "X3_PYME", "S" })
				EndIf
				
				// ========================================================
				// Ajustes para inclus�o de campo SX3 - FIM
				// ========================================================

			Else
				AutoGrLog( "ERRO: Propriedade 'Nome do campo' n�o identificada para atualiza��o do SX3." )
			EndIf
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
Static Function GetProperty(aProper, cProper)

	Local xRet
	Local nPos

	nPos:= aScan(aProper, {|x| x[1] == cProper })

	If nPos > 0
		//  Se informar a Propriedade SOMENTE_UPDATE n�o l�gica, considera verdadeiro.
		If cProper == "SOMENTE_UPDATE" .And. ( Len(aProper[nPos]) < 2 .Or. ValType( aProper[nPos][2] ) != "L" )
			xRet:= .T.
		Else
			xRet:= aProper[nPos][2]
		EndIf
	EndIf

	// Padr�o para a propriedade SOMENTE_UPDATE � .F.
	If cProper == "SOMENTE_UPDATE" .And. ValType( xRet ) != "L"
		xRet:= .F.
	EndIf

Return (xRet)
// FIM da Fun��o GetProperty
//====================================================================================================================\\



