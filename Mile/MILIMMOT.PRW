#INCLUDE "PROTHEUS.CH"



//====================================================================================================================\
/*/{Protheus.doc}MILIMMOT
  ====================================================================================================================
	@description
	Importa��o de cadastro de Motoristas via Mile

	@author TSC681 Thiago Mota
	@version 1.0
	@since 04/07/2018

	@obs
	Recebe os dados tratado da rotina MileImp e tenta cadastrar na DA4 usando o ExecAuto do OMSA040

/*/
//===================================================================================================================\
User Function MILIMMOT( lInterface, aDados )

	Local lRet:= .F.
	Local cCodMot //TODO: Definir como ser� gerado
	Local lIncCli
	Local cCpoLog
	Local nX

	Private lMsErroAuto		:= .F.
	Private lMsHelpAuto		:= .F.
	Private lAutoErrNoFile	:= .T.
	Private cObsLog			:= ""


	If .T.

		// ============================================
		// Valida��o de CNH
		// ============================================
		//TODO: Avaliar se vai precisar aqui, pois j� tem na valida��o do campo
		cNumCNH:= U_MILEDADO(@aDados, "DA4_NUMCNH")

		If ! U_CNHValid( cNumCNH )
			U_MILEDADO(@aDados, "DA4_NUMCNH","")
			cObsLog+= "CNH Invalido - D�gito verificador da CNH inv�lido"
		EndIf


		// ============================================
		// Alimenta o campo de log
		// ============================================
		If ! Empty(cObsLog)
			cObsLog:= "Erros encontrados na importa��o do Logix: " + cObsLog
			U_MILEDADO(@aDados, "DA4_ZLGIMP", cObsLog)
		EndIf

		aDados:= FWVetByDic( aDados, "DA4", /*lItens*/, /*nCpoPos*/ )
		MsExecAuto( {|x,y| OMSA040(x,y) }, aDados, If(lIncCli, 3, 4) )

		//Verifica se ouve algum erro
		If lMsErroAuto
			cLog:= "Erro ao cadastrar/alterar o Motorista " + cCodMot + ": " + CRLF
			aEval(GetAutoGrLog(), {|x| cDetalhe+= x + CRLF })
			lRet:= .F.
		EndIf


	Else
		cLog:= "CGC Inv�lido no arquivo (" + AllToChar(cCgcCli) + ")"
		cDetalhe:= "Verifique o CGC do Fornecedor no arquivo"
		lRet:= .F.
	EndIf

Return ( lRet )
// FIM da Funcao MILIMMOT
//======================================================================================================================



