#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'
#Include 'RestFul.CH'

#Define cUrl "https://payment.safrapay.com.br"
#Define cUrlPortal "https://portal-api.safrapay.com.br"
#Define cUrlBase "https://portal.safrapay.com.br"
#Define cMercTk ""
#Define cIdCli ""

/*/{Protheus.doc} GLkSafra
Funcao para geração do token de autorização.
@type function
@author Rivaldo Jr.
@since 29/09/2023
@return variant, Retorna a string do token.
/*/
User Function SafraGToken()

    Local cGeneratedToken  := ''
    Local cErro            := ''
    Local oRest            As Object
    Local oJson            As Object
    Local cPath          := "/v1/Login/GenerateToken"
    Local aHeader        := {"MerchantToken: "+cMercTk}

    oRest := FWRest():New(cUrlPortal)
    oJson := JSonObject():New()

    oRest:setPath(cPath)
    oRest:Post(aHeader)
    cErro := oJSon:fromJson(oRest:GetResult())

    If !oJson["success"]
        Return ""
    Endif

    If oJson:GetJSonObject('generatedToken') <> Nil
        cGeneratedToken := oJson:GetJSonObject('generatedToken')
    Else
        Return ""
    EndIf

Return "Bearer " + cGeneratedToken

/*/{Protheus.doc} GLkSafra
Funcao para geração do Link de pagamento SafraPay.
@type function
@author Rivaldo Jr.
@since 29/09/2023
@param nValor, numeric, Valor do link de pagamento.
@param cContato, character, Contato do cliente.
@param cEmail, character, Email do cliente.
@param nParc, numeric, Numero máximo de parcelas.
@return variant, Retorna um array contendo o ID do link e o proprio link.
/*/
Static Function GLkSafra(nValor, cContato, cEmail, nParc)
    Local cLinkPag   := ''
    Local cIdLink    := ''
    Local aHeader    := {}
    Local oRest      As Object
    Local oJson      As Object
    Local cAuth      := "Authorization: " + U_SafraGToken()
    Local cPath      := "/v2/paymentlink"
    Local cContent   := "Content-Type: application/json"
    Local cJsonBody  := ""
    Local nVal       := Val(StrTran(StrTran(AllTrim(Transform(nValor, "@E 999,999,999.99")),',',''),'.',''))

    Aadd(aHeader, cAuth         )
    Aadd(aHeader, cContent      )

    oRest := FWRest():New(cUrl)
    oJson := JSonObject():New()

    cJsonBody:= '{ '
    cJsonBody+=     '"amount": '+cValToChar(nVal)+','
    cJsonBody+=     '"description": "LinkPagamento Pharmapele",'
    cJsonBody+=     '"emailNotification": "'+cEmail+'",' // Email Padrão do cliente
    cJsonBody+=     '"phoneNotification": "'+cContato+'", '
    cJsonBody+=     '"maxInstallmentNumber": '+cValToChar(nParc)+' '
    cJsonBody+= '} '

    oRest:setPath(cPath)
    oRest:SetPostParams(cJsonBody)
    oRest:Post(aHeader)
    cErro := oJSon:fromJson(oRest:GetResult())

    If !oJson["success"]
        Return {}
    Endif

    cLinkPag  := cUrlBase+oJson:GetJSonObject('smartCheckoutUrl')
    cIdLink   := oJson:GetJSonObject('id')

Return { cIdLink, cLinkPag }

/*/{Protheus.doc} DelSafra
Função para cancelar e deletar um link de pagamento.
@type function
@author Rivaldo Jr.
@since 29/09/2023
@param cIdLink, character, ID do link de pagamento.
@return variant, Retorna true se localizou e deletou.
/*/
User Function DelSafra(cIdLink)
    Local cAuth          := "Authorization: " + U_SafraGToken()
    Local cContent       := "Content-Type: application/json"
    Local cMerchantID    := "MerchantId: "+cIdCli
    Local aHeader        := {}
    Local lRet           := .F.
    Local oRest          := FWRest():New(cUrlPortal)
    Local oJson          := JSonObject():New()

    Aadd(aHeader, cAuth)
    Aadd(aHeader, cMerchantID)
    Aadd(aHeader, cContent)

    oRest:setPath("/v1/smartcheckout/"+AllTrim(cIdLink))
    oRest:DELETE(aHeader)

    oJSon:fromJson(oRest:GetResult())
    
    If oJson["success"]
        lRet := .T.
    EndIf

Return lRet

