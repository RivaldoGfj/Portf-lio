#Include 'TOTVS.CH'

/*/{Protheus.doc} MT100TOK
Valida inclusão da NFE se atende as validações especificas.
@type function
@author Rivaldo Jr.
@since 22/11/2023
@return variant, Retorna true se ocorrer tudo ok.
/*/
User Function MT100TOK()
Local aArea	   := GetArea()
Local lRet     := .T.
Local cItAlert := ""
Local nCount   := 0
Local cNat     := ""
Local cProduto := ""
Local nQuebra  := chr(13) + Chr(10)

Local nPosCod  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_COD"} )
Local nPosIss  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_CODISS"} )
Local nPosInss := aScan( aHeader, { |x| Alltrim(x[2])=="D1_BASEINS"})
Local nPosPis  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_BASEPIS"})
Local nPosCsl  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_BASECSL"})
Local nPosCof  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_BASECOF"})
Local nPosIrr  := aScan( aHeader, { |x| Alltrim(x[2])=="D1_BASEIRR"})

/*
    22/11/2023 --- Cod.ERP - Carolina Tavares

    1- ROTINA DOCUMENTO DE ENTRADA.
    QUANDO NA ABA TIVER VALORES DOS SEGUINTES IMPOSTOS PIS RETENÇÃO (D1_BASEPIS),COFINS RETENÇÃO (D1_BASECOF),
    CSLL RETENÇÃO (D1_BASECSL), IRRF (D1_BASEIRR), NÃO PERMITIR INCLUIR NF OU CLASSIFICAR SEM FAZER O SEGUINTE CAMINHO:
    OUTRAS AÇOES - NAT. RENDIMENTO, POR ITEM. (DHR_NATREN)

    D1_BASEPIS, D1_BASECSL, D1_BASECOF, D1_BASEIRR

    2- SE TIVER INSS
    Se houver registro na tabela CDN com o campo CDN_CODLST
    para o produto + cod.serviço informado em
    B1_CODISS
*/

//Validacao 1
//If !EMPTY( cPis ) .AND. !EMPTY( cCsl ) .AND. !EMPTY( cCof ) .AND. !EMPTY( cIrr ) //se esses valores estiverem preenchidos
DbSelectArea("ZNR")
ZNR->(DbSetOrder(2))

For nCount := 1 to len(aCols)

	cCodProd := aCols[nCount,nPosCod]
	cCodIss  := aCols[nCount,nPosIss]
	cInss    := aCols[nCount,nPosInss]
	cPis     := aCols[nCount,nPosPis]
	cCsl     := aCols[nCount,nPosCsl]
	cCof     := aCols[nCount,nPosCof]
	cIrr     := aCols[nCount,nPosIrr]

	If ( !EMPTY(cPis) .AND. !EMPTY(cCsl) .AND. !EMPTY(cCof) ) .Or. !EMPTY(cIrr) .Or. ( !EMPTY(cPis) .AND. !EMPTY(cCsl) .AND. !EMPTY(cCof) .AND. !EMPTY(cIrr) )

		cProduto := aCols[nCount][aScan( aHeader, { |x| Alltrim(x[2])=="D1_COD"})]
		
		If Len(aColsDHR) >= nCount
			cNat 	 := aColsDHR[nCount][2][1][1]
			
			If Empty(aColsDHR[nCount][2][1][1]) //natureza de rendimento
				cItAlert += 'Item : '+aColsDHR[nCount][1]+nQuebra
			EndIf
		EndIf

		If !Empty(cNat)
			// Se a natureza de rendimento não estiver cadastrada, salva na tabela
			If !ZNR->(DbSeek(xFilial("ZNR")+CFORANTNFE+CLOJANTNFE+AllTrim(cProduto)+cNat))
				ZNR->(RecLock("ZNR",.T.))
					ZNR->ZNR_FILIAL := xFilial("ZNR")
					ZNR->ZNR_FORNEC := CFORANTNFE
					ZNR->ZNR_LOJA   := CLOJANTNFE
					ZNR->ZNR_NOME   := AllTrim(Posicione("SA2",1,xFilial("SA2")+CFORANTNFE+CLOJANTNFE,"A2_NOME"))
					ZNR->ZNR_PROD   := cProduto
					ZNR->ZNR_DESC   := AllTrim(aCols[nCount][aScan( aHeader, { |x| Alltrim(x[2])=="D1_DESCRI"})])
					ZNR->ZNR_NATURE := cNat 
				ZNR->(MsUnLock())
			EndIf
		EndIf

	EndIf

Next nCount

If !Empty(cItAlert)
	Help(" ",1,"ATENÇÃO!",,"Natureza de rendimento não informada nos Itens: "+nQuebra+cItAlert,3,1,,,,,,{"Informe as naturezas nos itens apontados para finalizar o processo com sucesso."})
	Return .F.
EndIf

//Validacao 2
aArea := CDN->(GetArea())
DbSelectArea("CDN")
CDN->(DbSetOrder(1)) //Posiciona no indice 1
CDN->(DbGoTop())

If !EMPTY( cInss ) //Se houver inss
	IF CDN->(DbSeek(FWxFilial("CDN") + cCodIss + cCodProd ))
		If !EMPTY(CDN->CDN_CODLST)
			lRet := .T.
		ENDIF
	Else
		MSGALERT( "Código de serviço inválido para esse produto: "+ cCodProd, "Código de Serviço" )
		return .F.
	ENDIF
ENDIF

RestArea(aArea)

Return lRet
