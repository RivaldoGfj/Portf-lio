#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'
#Include 'RestFul.CH'

#Define cUrl   "https://api.chat24.io"
#Define cToken ""

/*/{Protheus.doc} Chat2Desk
Consome APIs do Chat2Desk.
@type function
@author Rivaldo Jr.
@since 17/10/2023
@param cContato, character, Contato do cliente.
@param cIdOper, character, ID do operador.
@param cMensagem, character, Mensagem que será enviada.
@return variant, Retorna array contendo Strings de status, id do chat e id cliente.
/*/
User Function Chat2Desk(cContato, cIdOper, cMensagem)
    Local cID      := ""
    Local aRetorno := {}

    cID := U_ConsultaCli(cContato)
    Sleep(1000)

    If !Empty(cID)
        aRetorno := U_Mensagem(cID,cIdOper,cMensagem)
    EndIf

Return aRetorno

/*/{Protheus.doc} ConsultaCli
Consome API do Chat2Desk buscando o ID do cliente.
@type function
@author Rivaldo Jr.
@since 17/10/2023
@param cContato, character, Numero de contato do cliente.
@return variant, Retorna o ID do cliente.
/*/
User Function ConsultaCli(cContato)
    Local cAuth          := "Authorization: " + cToken
    Local cPath          := "/v1/clients?phone=" + cContato
    Local aHeader        := {}
    Local oRest          := FWRest():New(cUrl)
    Local cId            := ""
    Local cName          := ""
    Local a              := 1
    Local oJson          := JSonObject():New()

    Aadd(aHeader, cAuth)

    oRest:setPath(cPath)
    oRest:GET(aHeader)

    cErro := oJSon:fromJson(oRest:GetResult())

    If !empty(cErro)
        Return ""
    Endif
    
    For a := 1 To Len(oJson:GetJSonObject('data'))
        cId := cValToChar(oJson:GetJSonObject('data')[a]:GetJSonObject('id'))
        cName := cValToChar(oJson:GetJSonObject('data')[a]:GetJSonObject('name'))
    Next    

Return cId

/*/{Protheus.doc} CadastraCli
Consome API do Chat2Desk para cadastrar um cliente.
@type function
@author Rivaldo Jr.
@since 17/10/2023
@param cContato, character, Numero de contato do cliente.
@param cNome, character, Nome do cliente para registro.
@return variant, Retorna o ID do novo cliente.
/*/
User Function CadastraCli(cContato, cNome)
    Local cAuth          := "Authorization: " + cToken
    Local cContent       := "Content-Type: application/json"
    Local cPath          := "/v1/clients"
    Local cJson          := ""
    Local cId            := ""
    Local aHeader        := {}
    Local oRest          := FWRest():New(cUrl)
    Local oJson          := JSonObject():New()

    Aadd(aHeader, cAuth)
    Aadd(aHeader, cContent)

    cJson += '{'
    cJson += '"channel_id": 58547,' // ID do canal que possui a integração com o WhatsApp
    cJson += '"transport": "external",'
    cJson += '"phone": "'+cContato+'",' // +55 (XX) 9XXXX-XXXX
    cJson += '"nickname": "'+cNome+'"' // Nome do cliente
    cJson += '}'

    oRest:setPath(cPath)
    oRest:SetPostParams(cJson)
    oRest:POST(aHeader)

    cErro := oJSon:fromJson(oRest:GetResult())

    If !empty(cErro)
        Return 
    Endif
    
    cId := cValToChar(oJson:GetJSonObject('data'):GetJSonObject('id'))

Return cId

/*/{Protheus.doc} Mensagem
Consome API do Chat2Desk para envio da mensagem.
@type function
@author Rivaldo Jr.
@since 17/10/2023
@param cID, character, ID do cliente.
@param cIdOper, character, ID do operador.
@param cMensagem, character, Mensagem que será enviada.
@return variant, Retorna array contendo Strings de status, id do chat e id cliente.
/*/
User Function Mensagem(cID,cIdOper,cMensagem)
    Local cAuth          := "Authorization: " + cToken
    Local cContent       := "Content-Type: application/json"
    Local cPath          := "/v1/messages"
    Local aHeader        := {}
    Local cStatus        := ""
    Local cIdChat        := ""
    Local cIdCli         := ""
    Local cJson          := ""
    Local oRest          := FWRest():New(cUrl)
    Local oJson          := JSonObject():New()

    Aadd(aHeader, cAuth)
    Aadd(aHeader, cContent)

    cJson += '{ '
    cJson += '"client_id": ' + cID + ', '
    cJson += '"text": "' + cMensagem + '", '
    cJson += '"type": "to_client", '
    cJson += '"operator_id": '+cIdOper+' '
    cJson += '}'

    oRest:setPath(cPath)
    oRest:SetPostParams(cJson)
    oRest:POST(aHeader)

    cErro := oJSon:fromJson(oRest:GetResult())

    If oJson:GetJSonObject('status') == 'error'
        Help(" ",1,"ATENÇÃO!",,"Operador não localizado no Chat2Desk.",3,1,,,,,,{""})
        Return {}
    EndIf
    
    cStatus := oJson:GetJSonObject('status')// STATUS
    cIdChat := oJson["data"]["request_id"]  //ID DO CHAT
    cIdCli  := oJson["data"]["client_id"]   //ID DO CLIENTE

Return {cStatus, cIdChat, cIdCli}
