#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'
#Include 'RestFul.CH'

#Define cUrl "https://cieloecommerce.cielo.com.br"
#Define cClientID ""
#Define cClientSC ""

/*/{Protheus.doc} GLkCielo
Funcao para geração do Link de pagamento 
@type function
@author Rivaldo Jr.
@since 29/09/2023
@param nValor, numeric, Valor do link de pagamento.
@param nParc, numeric, Numero maximo de parcelas.
@return variant, Retorna um array contendo o ID do link e o proprio Link de pagamento.
/*/
User Function GLkCielo(nValor, nParc)
    Local cLinkPag   := ''
    Local cIdLink    := ''
    Local cErro      := ''
    Local oRest      As Object
    Local oJson      As Object
    Local cAuth      := "Authorization: " + U_CieloGToken()
    Local cPath      := "/api/public/v1/products/"
    Local cContent   := "Content-Type: application/json"
    Local cJsonBody  := ""
    Local aHeader    := {}
    Local sExpira    := DTOS(Date() + 2)
    Local cExpira    := SubStr(sExpira,1,4) + "-" + SubStr(sExpira,5,2) + "-" + SubStr(sExpira,7,2)

    Aadd(aHeader, cAuth         )
    Aadd(aHeader, cContent      )

    oRest := FWRest():New(cUrl)
    oJson := JSonObject():New()

    cJsonBody:= '{ '
    cJsonBody+= '"type": "Digital", '
    cJsonBody+= '"name": "LP Pharma", '
    cJsonBody+= '"description": "LinkPagamento Pharmapele", '
    cJsonBody+= '"price": '+cValToChar(nValor*100)+', '
    cJsonBody+= '"weight": 100, '
    cJsonBody+= '"expirationDate": "'+cExpira+'", '
    cJsonBody+= '"maxNumberOfInstallments": "'+cValToChar(nParc)+'", '
    cJsonBody+= '"quantity": 5, '
    cJsonBody+= '"sku": "LinkPagamento", '
    cJsonBody+= '"shipping": { '
    cJsonBody+= '"type": "WithoutShipping", '
    cJsonBody+= '"name": "SFrete", '
    cJsonBody+= '"price": "10" '
    cJsonBody+= '}, '
    cJsonBody+= '"softDescriptor": "Pharmapele" '
    cJsonBody+= '} '

    oRest:setPath(cPath)
    oRest:SetPostParams(cJsonBody)
    oRest:Post(aHeader)
    cErro := oJSon:fromJson(oRest:GetResult())

    If !empty(cErro)
        MsgStop(cErro,"JSON PARSE ERROR")
        Return ""
    Endif

    If oJson:GetJSonObject('shortUrl') <> Nil
        cLinkPag  := oJson:GetJSonObject('shortUrl')
        cIdLink   := oJson:GetJSonObject('id')
    Else 
        Return {}
    EndIf

Return { cIdLink, cLinkPag }

/*/{Protheus.doc} CieloGToken
Funcao para geração do token de autorização.
@type function
@author Rivaldo Jr.
@since 29/09/2023
@return variant, Retorna a string do token.
/*/
User Function CieloGToken()
    Local cToken           := ''
    Local cTkType          := ''
    Local cErro            := ''
    Local oRest            As Object
    Local oJson            As Object
    Local cPath            := "/api/public/v2/token"
    Local aHeader          := {"Authorization: Basic " + Encode64(cClientID + ":" + cClientSC)}

    oRest := FWRest():New(cUrl)
    oJson := JSonObject():New()

    oRest:setPath(cPath)
    oRest:Post(aHeader)
    cErro := oJSon:fromJson(oRest:GetResult())

    If !empty(cErro)
        FWAlertWarning(cErro,"JSON PARSE ERROR")
        Return ""
    Endif

    If oJson:GetJSonObject('access_token') <> Nil
        cToken  := oJson:GetJSonObject('access_token')
        cTkType := oJson:GetJSonObject('token_type')
    Else 
        FWAlertWarning("Erro no servidor da Cielo, Não é possível gerar o Link de pagamento.","Atenção!")
        Return ""
    EndIf

Return cTkType + " " + cToken


/*/{Protheus.doc} DelCielo
Função para cancelar e deletar um link de pagamento.
@type function
@author Rivaldo Jr.
@since 29/09/2023
@param cIdLink, character, ID do link de pagamento.
@return variant, Retorna true se localizou e deletou.
/*/
User Function DelCielo(cIdLink)
    Local cAuth          := "Authorization: " + U_CieloGToken()
    Local cContent       := "Content-Type: application/json"
    Local aHeader        := {}
    Local lRet           := .F.
    Local oRest          := FWRest():New(cUrl)
    Local oJson          := JSonObject():New()

    Aadd(aHeader, cAuth)
    Aadd(aHeader, cContent)

    oRest:setPath("/api/public/v1/products/"+AllTrim(cIdLink))
    oRest:DELETE(aHeader)

    oJSon:fromJson(oRest:GetResult())
    
    If oRest:oResponseh:cStatusCode == "204"
        lRet := .T.
    EndIf

Return lRet
