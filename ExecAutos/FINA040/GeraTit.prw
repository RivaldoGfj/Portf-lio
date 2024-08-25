#include 'Protheus.Ch'

/*/{Protheus.doc} GeraTit
Geração do Titulo com o Vlr Correspondente ao juros
@type function
@author rivaldojr
@since 25/08/2024
@param cNum, character, Numero do titulo.
@param cParc, character, Parcela do titulo.
@param cCliente, character, Código do cliente.
@param cLoja, character, Loja do cliente.
@param nNewVlr, numeric, Valor do titulo.
@param cVend, character, Código do vendedor.
@return variant, Retorna true se deu certo.
/*/
Static Function GeraTit(cNum, cParc, cCliente, cLoja, nNewVlr, cVend, cEstab)
	Local aDados            := {}
	Local aAreaSE1          := SE1->(GetArea())
	Local cPrefix			:= "600"
	Local cTipo 			:= "NDC"
	Local cNumParc			:= AllTrim(cNum)+Alltrim(cParc)
	Local lRet 				:= .T.
	
	DbSelectArea('SE1')
	SE1->(DbSetOrder(1))
	If !SE1->(DbSeek(xFilial('SE1')+"600"+cNum+cParc+"NDC"))
		Private lMsErroAuto := .F.
		aDados := { { "E1_PREFIXO"  , cPrefix             					, NIL },;
					{ "E1_NUM"      , Padr(cNumParc,TaxSX3("E1_NUM"))[1]	, NIL },;
					{ "E1_TIPO"     , cTipo             					, NIL },; 
					{ "E1_LOC"     	, "10"             					    , NIL },;
					{ "E1_NATUREZ"  , "600001"          					, NIL },;
					{ "E1_CLIENTE"  , cCliente   							, NIL },;
					{ "E1_LOJA"     , cLoja   								, NIL },;
					{ "E1_EMISSAO"  , dDatabase								, NIL },;
					{ "E1_VENCTO"   , dDatabase								, NIL },;
					{ "E1_VENCREA"  , dDatabase								, NIL },;
					{ "E1_VALOR"    , nNewVlr   							, NIL },;
					{ "E1_VEND1"  	, cVend									, NIL },;
					{ "E1_COMIS1"   ,   0		                            , NIL }}

		MsExecAuto( { |x,y| FINA040(x,y)} , aDados, 3)  // 3 - Inclusão, 4 - Alteração, 5 - Exclusão
		If lMsErroAuto
			MostraErro()
			lRet := .F.
		Endif
	Endif
	
	RestArea(aAreaSE1)

Return lRet
