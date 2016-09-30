#Include 'Protheus.ch'

//====================================================================================================================\\
/*/{Protheus.doc}${name}
  ====================================================================================================================
	@description
	Relat�rio ${name} - ${title}
	${long_description}

	@author		${author}
	@version	${version}
	@since		${date}
	@return		Nil			, Nil				, N�o se aplica

	@obs
	Lista de par�metros:	${paramlist}
	Grupo de perguntas:	${grupo_perguntas}
	�reas utilizadas:		${Areas}
	Backup e Restore das �reas: ${lBackupAreas}
	M�todo de Sele��o:	${tipoQuery}  (0 - TReport, 1 = TCQuery(cQuery), 2 = Embedded SQL )

	${obs_description}

	@sample	U_name(${paramlist})
	@example	examples

/*/
//===================================================================================================================\\
User Function ${name}(${paramlist})
	Local lBkpArea		:= ${lBackupAreas}
	Local aAreaBkp		:= {}
	Local oReport

	If lBkpArea // Backup das �reas atuais
		aEval({Areas}, { |area| aAdd(aAreaBkp, (area)->(GetArea()) ) } )
		aAdd(aAreaBkp, GetArea())
	EndIf

	oReport := ReportDef()
	oReport:PrintDialog()

	If lBkpArea // Restaura as �reas anteriores
		aEval(aAreaBkp, {|area| RestArea(area)})
	EndIf
Return ( Nil )
// FIM do Relat�rio ${name}
//======================================================================================================================



//====================================================================================================================\\
/*/{Protheus.doc}ReportDef
  ====================================================================================================================
	@description
	Relat�rio ${name} - ${title}
	A funcao estatica ReportDef devera ser criada para todos os relatorios que poderao ser agendados pelo usuario.

	@author		${author}
	@version	${version}
	@since		${date}
	@return		oReport		, Objeto		, Objeto da Classe TReport com as defini��es de impress�o


	@obs		Par�metros passados para a ReportPrint: oReport${paramlistPrint}
				${obs_description}

/*/
//===================================================================================================================\\
Static Function ReportDef()
	Local oReport
	Local cNomRel	:= '${name}'	//Nome do relatorio.
	Local cTitRel	:= '${title}' //Titulo do relatorio.
	Local cDesRel	:= '${long_description}' //Descricao do relatorio.
	Local cGruPer	:= '${grupo_perguntas}' // Grupo de perguntas

	oReport := TReport():New(cNomRel,cTitRel,cGruPer, {|oReport| ReportPrint(oReport${paramlistPrint})},cDesRel,;
								/*lLandscape*/,/*uTotalText*/,/*lTotalInLine*/,/*cPageTText*/,/*lPageTInLine*/,/*lTPageBreak*/,/*nColSpace*/)

	${cursor}

	If !Empty(oReport:uParam)
        AjusParam(cGruPer)
        Pergunte(oReport:uParam,.F.)
	EndIf

Return (oReport)
// FIM da Fun��o ReportDef
//======================================================================================================================



//====================================================================================================================\\
/*/{Protheus.doc}ReportPrint
  ====================================================================================================================
	@description
	Relat�rio ${name} - ${title}
	Fun��o respons�vel pela execu��o do relat�rio

	@author		${author}
	@version	${version}
	@since		${date}
	@return		Nil			, Nil				, N�o se aplica

	@obs		Lista de par�metros: oReport${paramlistPrint}

/*/
//===================================================================================================================\\
Static Function ReportPrint(oReport${paramlistPrint})

	Local cAliasQry := GetNextAlias()
	Local nTipQuery := ${tipoQuery}

	MakeSqlExpr(oReport:uParam)

	If Empty(nTipQuery) .Or. nTipQuery==0
		oReport:Section(1):Print()
	Else
		oReport:SetMeter(ExecRelQry(nTipQuery, oReport, cAliasQry))

		dbSelectArea(cAliasQry)
		dbGoTop()
		While !oReport:Cancel() .And. !(cAliasQry)->(Eof())
			oReport:Section(1):Section(1):Init()
			oReport:Section(1):Section(1):PrintLine()
			oReport:Section(1):Section(1):Finish()
			dbSelectArea(cAliasQry)
			dbSkip()
			oReport:IncMeter()
		EndDo

		oReport:Section(1):Finish()
		oReport:Section(1):SetPageBreak(.T.)

	EndIf


Return ( Nil )
// FIM da Fun��o ReportPrint
//======================================================================================================================



//====================================================================================================================\\
/*/{Protheus.doc}ExecRelQry
  ====================================================================================================================
	@description
	Relat�rio ${name} - ${title}
	Fun��o que ajusta o grupo de perguntas utilizado nos filtros do relat�rio

	@author		${author}
	@version	${version}
	@since		${date}
	@return		nCount		, Num�rico		, Quantidade de registros na Query

	@param		nTipQuery	, Num�rico		, Indica o tipo de Query a utilizar (1 = Query TXT, 2 = Embedded SQL)
	@param		oReport		, Objeto		, Objeto da Classe TReport com as defini��es de impress�o
	@param		cAliasQry	, Caractere	, Alias da para a Query

/*/
//===================================================================================================================\\
Static Function ExecRelQry(nTipQuery, oReport, cAliasQry)
	Local nCount	:= 0

	//TODO: Implementar cQuery
	If nTipQuery == 2

		oReport:Section(1):BeginQuery()

		BeginSql Alias cAliasQry
			SELECT
				SA1.*

			FROM
				%table:SA1% SA1

			WHERE
					  SA1.A1_FILIAL = %xFilial:SA1%
				AND SA1.%NotDel%

			ORDER BY
				%Order:SA1%

		EndSql

		oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

	EndIf

	Count to nCount //TODO: Ver se funciona com Embedded


Return ( nCount )
// FIM da Fun��o ExecRelQry
//======================================================================================================================



//====================================================================================================================\\
/*/{Protheus.doc}AjusParam
  ====================================================================================================================
	@description
	Relat�rio ${name} - ${title}
	Fun��o que ajusta o grupo de perguntas utilizado nos filtros do relat�rio

	@author		${author}
	@version	${version}
	@since		${date}
	@return		Nil			, Nil				, N�o se aplica

	@param		cGruPer		, Caractere	, Grupo de perguntas do SX1

/*/
//===================================================================================================================\\
Static Function AjusParam(cGruPer)

Return ( Nil )
// FIM da Fun��o AjusParam
//======================================================================================================================
