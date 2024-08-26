#Include "Totvs.Ch"
#Include "Topconn.ch"

/*/{Protheus.doc} MODEL_ABA
Ponto de entrada MVC da rotina FISA001
@type function
@author Rivaldo Jr.
@since 24/01/2024
@return variant, retorno variavel
/*/
User Function MODEL_ABA()
    Local aParam   := PARAMIXB
    Local xRet     := .T.
    Local oModel   := ''
    Local cIdPonto := ''
    Local cIdModel := ''
    Local cQry     := ""
    Local cFilSer   := FormatIn(SUPERGETMV( "ES_DCSSPD", .F., "FAT" ), "/")
  
    If aParam <> NIL
        oModel  := aParam[1]
        cIdPonto:= aParam[2]
        cIdModel:= aParam[3]

        If(cIdPonto == 'MODELVLDACTIVE')

            cQry := " SELECT F4_TPREG, F4_CSTPIS, F4_CSTCOF, F4_TPREG, "
            cQry += " D2_CLIENTE, D2_LOJA, D2_EMISSAO, D2_COD, D2_DOC, D2_SERIE, D2_CONTA, D2_VALBRUT, D2_ALQPIS, D2_VALIMP6, D2_BASIMP5, D2_ALQCOF, D2_VALIMP5 "
            cQry += " FROM "+RetSqlName("SD2")+" SD2 "
            cQry += "   INNER JOIN "+RetSqlName("SF2")+" SF2 ON F2_FILIAL = D2_FILIAL AND F2_DOC = D2_DOC AND F2_SERIE = D2_SERIE AND F2_CLIENTE = D2_CLIENTE AND F2_LOJA = D2_LOJA AND F2_ESPECIE = 'FAT' AND SF2.D_E_L_E_T_ <> '*' "
            cQry += "   INNER JOIN "+RetSqlName("SF4")+" SF4 ON F4_FILIAL = '"+xFilial('SF4')+"' AND F4_CODIGO = D2_TES AND F4_DUPLIC = 'N' AND SF4.D_E_L_E_T_ <> '*' "
            cQry += "   LEFT  JOIN "+RetSqlName("CF8")+" CF8 ON CF8_FILIAL = D2_FILIAL AND CF8_DOC = D2_DOC AND CF8_SERIE = D2_SERIE AND CF8.D_E_L_E_T_ <> '*'  "
            cQry += " WHERE CF8_FILIAL IS NULL "
            cQry += "  AND D2_FILIAL = '"+xFilial('SD2')+"' "
            cQry += "  AND D2_CF     = '000' "
            //cQry += "  AND D2_DOC    = '000034414' "
            cQry += "  AND D2_SERIE IN"+cFilSer+" "
            //cQry += "  AND D2_EMISSAO  BETWEEN '"+DtoS(dDataIni)+"' AND '"+DtoS(dDataFim)+"' "
            cQry += "  AND SD2.D_E_L_E_T_ <> '*' "
            MpSysOpenQuery(cQry, "TRBCF8")

            While !TRBCF8->(Eof())

                GRAVACF8() // Grava as faturas na rotina FISA048 ( Demais documentos PIS COFINS)

                TRBCF8->(dbSkip())
            End
            TRBCF8->(dbCloseArea())

        EndIf

        If(cIdPonto == 'BUTTONBAR')
           xRet := { {'Ajustar apura  o das faturas', 'BUDGET', { |x| Processa({|| VeriCL2()},"Aguarde um momento, Ajustando registros...") }, 'Bot o customizado' } } //Uma op  o nova ser  adicionada ao menu Outras A  es
        EndIf

    EndIf

Return xRet

/*/{Protheus.doc} MODEL_ABA
Funcao para inclusao de registro na rotina Outros Documentos PIS/COFINS
@type function
@author Rivaldo Jr.
@since 24/01/2024
@return variant, retorno variavel
/*/
Static Function GRAVACF8()
    Local oModel    := Nil
    Local lRet      := .F.

    oModel := FWLoadModel("FISA048")
    oModel:SetOperation(3)

    If(oModel:CanActivate())           
        oModel:Activate()

        oModel:SetValue("MODEL_CF8","CF8_TPREG"  , '2'                      ) // N o cumulativo
        oModel:SetValue("MODEL_CF8","CF8_INDOPE" , '1'                      ) // Opera  o de receita
        oModel:SetValue("MODEL_CF8","CF8_CLIFOR" , TRBCF8->D2_CLIENTE       ) 
        oModel:SetValue("MODEL_CF8","CF8_LOJA"   , TRBCF8->D2_LOJA          ) 
        oModel:SetValue("MODEL_CF8","CF8_DTOPER" , StoD(TRBCF8->D2_EMISSAO) ) // Dt.Opera  o
        oModel:SetValue("MODEL_CF8","CF8_VLOPER" , TRBCF8->D2_VALBRUT       ) // Vl.Opera  o
        oModel:SetValue("MODEL_CF8","CF8_CSTPIS" , TRBCF8->F4_CSTPIS        ) // Sit.Trib.PIS
        oModel:SetValue("MODEL_CF8","CF8_BASPIS" , TRBCF8->D2_VALBRUT       ) // Base PIS
        oModel:SetValue("MODEL_CF8","CF8_ALQPIS" , TRBCF8->D2_ALQPIS        ) // Aliquota PIS
        oModel:SetValue("MODEL_CF8","CF8_VALPIS" , TRBCF8->D2_VALIMP6       ) // Valor PIS
        oModel:SetValue("MODEL_CF8","CF8_CSTCOF" , TRBCF8->F4_CSTCOF        ) // Sit.Trib.COF
        oModel:SetValue("MODEL_CF8","CF8_BASCOF" , TRBCF8->D2_BASIMP5       ) // Base Cofins
        oModel:SetValue("MODEL_CF8","CF8_ALQCOF" , TRBCF8->D2_ALQCOF        ) // Aliq.COFINS
        oModel:SetValue("MODEL_CF8","CF8_VALCOF" , TRBCF8->D2_VALIMP5       ) // Valor COFINS
        oModel:SetValue("MODEL_CF8","CF8_INDORI" , ''                       )         
        oModel:SetValue("MODEL_CF8","CF8_CODCTA" , TRBCF8->D2_CONTA         ) // Conta contabil
        oModel:SetValue("MODEL_CF8","CF8_DESCPR" , "Opera  o referente o T tulo :"+TRBCF8->D2_DOC) // Descri  o
        oModel:SetValue("MODEL_CF8","CF8_RECBRU" , '1'                      )         
        oModel:SetValue("MODEL_CF8","CF8_PART"   , ''                       )         
        oModel:SetValue("MODEL_CF8","CF8_SERIE"  , TRBCF8->D2_SERIE         ) // Serie da Nota fiscal
        oModel:SetValue("MODEL_CF8","CF8_DOC"    , TRBCF8->D2_DOC           ) // Numero da Nota fiscal
            
        If (oModel:VldData()) /*Valida o modelo como um todo*/
            oModel:CommitData()
            If Empty(CF8->CF8_CLIFOR)
                CF8->(RecLock("CF8",.F.))
                    CF8->CF8_CLIFOR := TRBCF8->D2_CLIENTE
                    CF8->CF8_LOJA   := TRBCF8->D2_LOJA
                CF8->(MsUnLock())
            EndIf
            lRet := .T.
        EndIf
    EndIf
    oModel:DeActivate()                         

Return lRet

/*/{Protheus.doc} MODEL_ABA
Funcao para corrigir a gravacao dos registros na CL2
@type function
@author Rivaldo Jr.
@since 24/01/2024
@return variant, retorno variavel
/*/
Static Function VeriCL2()
    Local cQry      := ""
    Local cFilSer   := FormatIn(SUPERGETMV( "ES_DCSSPD", .F., "FAT" ), "/")

    cQry := " SELECT D2_EMISSAO, D2_DOC, D2_SERIE, CL2_ID "
    cQry += " FROM "+RetSqlName("SD2")+" SD2 "
    cQry += "   INNER JOIN "+RetSqlName("SF2")+" SF2 ON F2_FILIAL = D2_FILIAL AND F2_DOC = D2_DOC AND F2_SERIE = D2_SERIE AND F2_CLIENTE = D2_CLIENTE AND F2_LOJA = D2_LOJA AND F2_ESPECIE = 'FAT' AND SF2.D_E_L_E_T_ <> '*' "
    cQry += "   INNER JOIN "+RetSqlName("SF4")+" SF4 ON F4_FILIAL = '"+xFilial('SF4')+"' AND F4_CODIGO = D2_TES AND F4_DUPLIC = 'N' AND SF4.D_E_L_E_T_ <> '*' "
    cQry += "   INNER JOIN "+RetSqlName("CF8")+" CF8 ON CF8_FILIAL = D2_FILIAL AND CF8_DOC = D2_DOC AND CF8_SERIE = D2_SERIE AND CF8.D_E_L_E_T_ <> '*'  "
    cQry += "   INNER JOIN "+RetSqlName("CL2")+" CL2 ON CL2_FILIAL = D2_FILIAL AND CL2_CLIFOR = D2_CLIENTE AND CL2_LOJA = D2_LOJA "//AND CL2_VLOPER = D2_VALBRUT "
    cQry += "   AND CL2.D_E_L_E_T_ <> '*' AND CL2_PER = D2_EMISSAO AND CL2_IDCF8 = CF8_CODIGO "//AND CL2_NUMTIT IS NULL "//AND CL2_ALIAS IS NULL "
    cQry += " WHERE D2_CF     = '000' "
    //cQry += "  AND CL2_NUMTIT = '' "
    cQry += "  AND D2_SERIE IN"+cFilSer+" "
    cQry += "  AND SD2.D_E_L_E_T_ <> '*' "
    cQry += "  GROUP BY CL2_ID, D2_EMISSAO, D2_DOC, D2_SERIE "
    MpSysOpenQuery(cQry, "TRBCL2")

    DbSelectArea("CL2")
    CL2->(DbSetOrder(1))
    If !TRBCL2->(Eof())
        While !TRBCL2->(Eof())
            If CL2->(MsSeek(xFilial("CL2") + TRBCL2->D2_EMISSAO + "F100" + TRBCL2->CL2_ID))
                If Empty(CL2->CL2_NUMTIT)
                    Incproc("FATURA "+TRBCL2->D2_DOC)
                    CL2->(RecLock("CL2",.F.))
                        CL2->CL2_NUMTIT := TRBCL2->D2_DOC
                        CL2->CL2_PREFIX := TRBCL2->D2_SERIE
                        CL2->CL2_ALIAS  := 'SA1'
                    CL2->(MsUnLock())
                EndIf
            EndIf
            TRBCL2->(dbSkip())
        End
        FwAlertSucess("Apuracao de faturas ajustadas.","Sucesso!")
    Else 
        FwAlertWarning("Nao foram encontradas apuracoes de faturas a ajustar","Atencao!")
    EndIf
    TRBCL2->(dbCloseArea())

Return 
