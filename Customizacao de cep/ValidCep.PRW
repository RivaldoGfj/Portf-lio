#Include 'Protheus.ch'
#Include 'RestFul.CH'

/*/{Protheus.doc} ValidCep
// Utilidade : Consulta o CEP digitado na tabela ZRC Customizada, caso não    |
//             encontrevia, busca o cep por consumo de API para os cadastros: |
//             clientes, fornecedores, vendedores e transportadoras           |
//             e preenchimento dos campos com os dados de retorno.            |
@type function
@author Rivaldo Jr.
@since 11/11/2022
@param cCep, character, String com o código do cep digitado.
@return variant, Retorna true se o cep for válido.
/*/
User FuncTion ValidCep(cCep)
  Local cURL       := "https://viacep.com.br"
  Local cContent   := "Content-Type: application/json"
  Local oRest      := FWRest():New(cURL)
  Local aHeader    := {}
  Local lRet       := .T.
  Local lCepTab    := .F.
  Local cRotina    := FunName()
  Local lZRC       := FwAliasIndic("ZRC")
  Private oJson    := JSonObject():New()

  Aadd(aHeader, cContent) //Cabeçalho de requisição

  If lZRC
    DbSelectArea("ZRC")
    ZRC->(DbSetOrder(1))

    If ZRC->(DbSeek(FwXfilial("ZRC")+cCep))

      // TRATAMENTO PARA VERIFICAR E ALTERAR O CÓDIGO DO MUNICIPIO CASO ESTEJA DIVERGENTE 
      // ENTRE A TABELA CC2 E ZRC 
      DbSelectArea("CC2")
      CC2->(DbSetOrder(4))

      If CC2->(DbSeek(FwXfilial("CC2")+AllTrim(ZRC->(ZRC_EST))+Upper(FwNoAccent(AllTrim(ZRC->ZRC_MUN)))))
        If (CC2->CC2_CODMUN <> ZRC->ZRC_CODMUN) // SE DIVERGENTE, CORRIGI NA TABELA ZRC
          ZRC->(RecLock("ZRC",.F.))
            ZRC->ZRC_CODMUN := CC2->CC2_CODMUN
          ZRC->(MsUnlock())
        EndIf
      EndIf

      lCepTab := .T.
      Atualiza(cRotina, lCepTab)

    Else  

      oRest:setPath("/ws/"+cCep+"/json/") //Endpoint

      If oRest:GET(aHeader) //Consumo da API da VIACEP

        oJSon:fromJson(oRest:GetResult())

        If ojson["erro"] <> NIL

          FWAlertError('Por favor, digite um cep válido.','Cep Inválido!')
          lRet := .F.
          Return lRet

        ElseIf oRest:GetHTTPCode() == "200"

          //Gravo o novo cep na tabela customizada de ceps
          ZRC->(RecLock("ZRC",.T.))
            ZRC->ZRC_CEP     := Padr(cCep,TamSx3("ZRC_CEP")[1])
            ZRC->ZRC_EST     := Padr(DecodeUTF8(oJson:GetJsonObject('uf'),"cp1252")        ,TamSx3("ZRC_EST")[1])
            ZRC->ZRC_MUN     := Padr(DecodeUTF8(oJson:GetJsonObject('localidade'),"cp1252"),TamSx3("ZRC_MUN")[1])
            ZRC->ZRC_CODMUN  := Padr(SubStr(DecodeUTF8(oJson:GetJsonObject('ibge'),"cp1252"), 3, 5) ,TamSx3("ZRC_CODMUN")[1])
            ZRC->ZRC_BAIRRO  := Padr(DecodeUTF8(oJson:GetJsonObject('bairro'),"cp1252")    ,TamSx3("ZRC_BAIRRO")[1])
            ZRC->ZRC_END     := Padr(DecodeUTF8(oJson:GetJsonObject('logradouro'),"cp1252"),TamSx3("ZRC_END")[1])
          ZRC->(MsUnlock())

          Atualiza(cRotina, lCepTab)

        Endif

      EndIf

    EndIf

  Else
    FWAlertError("Tabela Não Encontrada -> ZRC", "ATENÇÃO!")
  EndIf

  //Limpa o Objeto
  FreeObj(oRest)
  FreeObj(oJson)

Return lRet

Static Function Atualiza(cRotina, lCepTab)

  Do Case
    Case cRotina $ "CRMA980|MATA030" //Clientes

      M->A1_BAIRRO := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('bairro'),"cp1252")    ,ZRC->ZRC_BAIRRO),TamSx3("A1_BAIRRO")[1])
      M->A1_MUN    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('localidade'),"cp1252"),ZRC->ZRC_MUN)   ,TamSx3("A1_MUN")[1])
      M->A1_EST    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('uf'),"cp1252")        ,ZRC->ZRC_EST)   ,TamSx3("A1_EST")[1])
      M->A1_ESTADO := Padr(Iif(!lCepTab,''                                                    ,ZRC->ZRC_ESTADO),TamSx3("A1_ESTADO")[1])
      M->A1_COD_MUN:= Padr(Iif(!lCepTab,SubStr(DecodeUTF8(oJson:GetJsonObject('ibge'),"cp1252"), 3, 5),ZRC->ZRC_CODMUN),TamSx3("A1_COD_MUN")[1])
      M->A1_END    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('logradouro'),"cp1252"),ZRC->ZRC_END)   ,TamSx3("A1_END")[1])

    Case cRotina == "MATA020" //Fornecedores

      M->A2_BAIRRO := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('bairro'),"cp1252")    ,ZRC->ZRC_BAIRRO),TamSx3("A2_BAIRRO")[1])
      M->A2_MUN    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('localidade'),"cp1252"),ZRC->ZRC_MUN)   ,TamSx3("A2_MUN")[1])
      M->A2_EST    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('uf'),"cp1252")        ,ZRC->ZRC_EST)   ,TamSx3("A2_EST")[1])
      M->A2_ESTADO := Padr(Iif(!lCepTab,''                                                    ,ZRC->ZRC_ESTADO),TamSx3("A2_ESTADO")[1])
      M->A2_COD_MUN:= Padr(Iif(!lCepTab,SubStr(DecodeUTF8(oJson:GetJsonObject('ibge'),"cp1252"), 3, 5),ZRC->ZRC_CODMUN),TamSx3("A2_COD_MUN")[1])
      M->A2_END    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('logradouro'),"cp1252"),ZRC->ZRC_END)   ,TamSx3("A2_END")[1])

    Case cRotina == "MATA040" //Vendedores
      
      M->A3_BAIRRO := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('bairro'),"cp1252")    ,ZRC->ZRC_BAIRRO),TamSx3("A3_BAIRRO")[1])
      M->A3_MUN    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('localidade'),"cp1252"),ZRC->ZRC_MUN)   ,TamSx3("A3_MUN")[1])
      M->A3_EST    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('uf'),"cp1252")        ,ZRC->ZRC_EST)   ,TamSx3("A3_EST")[1])
      M->A3_END    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('logradouro'),"cp1252"),ZRC->ZRC_END)   ,TamSx3("A3_END")[1])

    Case cRotina == "MATA050" //Transportadoras

      M->A4_BAIRRO := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('bairro'),"cp1252")    ,ZRC->ZRC_BAIRRO),TamSx3("A4_BAIRRO")[1])
      M->A4_MUN    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('localidade'),"cp1252"),ZRC->ZRC_MUN),TamSx3("A4_MUN")[1])
      M->A4_EST    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('uf'),"cp1252")        ,ZRC->ZRC_EST),TamSx3("A4_EST")[1])
      M->A4_END    := Padr(Iif(!lCepTab,DecodeUTF8(oJson:GetJsonObject('logradouro'),"cp1252"),ZRC->ZRC_END),TamSx3("A4_END")[1])
  EndCase

Return 
