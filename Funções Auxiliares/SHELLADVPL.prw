#Include 'Protheus.ch'

//====================================================================================================================\\
/*/{Protheus.doc}SHELLADVPL
  ====================================================================================================================
	@description
	Tela auxiliar para avalia��o de express�es no Protheus

	@author	TSC681 Thiago Mota <thiago.mota@totvs.com.br>
	@version	1.0
	@since		2 de mar de 2017
	@return	xRet, Padr�o: Nulo

	@sample	U_SHELLADVPL()

/*/
//===================================================================================================================\\
User Function SHELLADVPL(${param}, ${param_type}, ${param_descr})
	Local aAreaBkp:= {}
	Local xRet		:= Nil

	// Backup das �reas atuais
	aEval({Areas}, { |area| aAdd(aAreaBkp, (area)->(GetArea()) ) } )
	aAdd(aAreaBkp, GetArea())



	aEval(aAreaBkp, {|area| RestArea(area)}) // Restaura as �reas anteriores
Return ( xRet )
// FIM da Funcao SHELLADVPL
//======================================================================================================================


