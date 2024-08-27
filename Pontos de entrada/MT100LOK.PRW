#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} ValDocE
Ponto de Entrada Para Validação de Linha 
Na Geração do Documento de Entrada.
@type function
@author Rivaldo Jr.
@since 20/09/2022
@return variant, Retorna true se a nota for valida.
/*/
Static Function ValDocE()
    Local lRet       := .T.
    Local nNFOri     := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D1_NFORI"})

    If !aCols[n,Len(aHeader)+1] .And. cTipo == 'D' .And. cFormul == 'N'
        If Empty(aCols[n,nNFOri])
            MsgInfo("Nota de origem não informada!")
            lRet := .F.
        Endif
    Endif

Return lRet
