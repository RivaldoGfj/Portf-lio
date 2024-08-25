#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} ApontaOp
Função Automática para apontar uma ordem de produção
@type function 
@author rivaldojr
@since 25/08/2024
@param cNumOp, character, Numero da OP.
@param cTPMovime, character, Tipo do movimento.
@param cLote, character, código do lote.
@return variant, Retorna true se deu certo.
/*/
User Function ApontaOp(cNumOp, cTPMovime, cLote)
	Local aItens := {}
	Local lRet 	 := .F.
	Private lMsErroAuto := .F.

	aadd(aItens,{"D3_OP"   	 , cNumOp  	,    Nil})
	aadd(aItens,{"D3_TM"   	 , cTPMovime,    Nil})
	aadd(aItens,{"D3_PERDA"	 , 0 		,    Nil})
	aadd(aItens,{"D3_QUANT"	 , 1 		,    Nil})
	aadd(aItens,{"D3_LOTECTL", cLote  	,    Nil})

	MsExecAuto({|x,y| Mata250(x,y)},aItens,3)

	If  lMsErroAuto
		MSGINFO( "Erro na rotina automática." , "Atenção"  )
		Mostraerro()
		lRet := .F.
	Endif

return lRet
