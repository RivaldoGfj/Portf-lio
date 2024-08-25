#INCLUDE "Protheus.ch"
/*/{Protheus.doc} FinOrc
ExecAuto para finalizar um orçamento do venda assistida - LOJA701.
@type function
@author Rivaldo Jr.
@since 25/08/2024
@param cNumOrc, character, Código do orçamento.
@return variant, Retorna true se ocorreu tudo certo.
/*/
User Function FinOrc(cNumOrc)
    Local aArea         := GetArea()
    Local aSL1Area      := SL1->(GetArea())
    Local aSL2Area      := SL2->(GetArea())
    Local aSL4Area      := SL4->(GetArea())
    Local aSx3Area      := SX3->(GetArea())
    Local _aCab         := {} //Array do Cabeçalho do Orçamento
    Local _aItem        := {} //Array dos Itens do Orçamento
    Local _aParcela     := {} //Array das Parcelas do Orçamento
    Local aiErro        := {}
    Local nOpc          := 4
    Local lRet          := .F.
    Private lMsHelpAuto := .T. //Variavel de controle interno do ExecAuto
    Private lMsErroAuto := .F. //Variavel que informa a ocorrência de erros no ExecAuto
    Private lAutoErrNoFile  := .T.
    Private INCLUI      := .T. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
    Private ALTERA      := .F. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão

    dbSelectArea("SL1")
    SL1->(dbSetOrder(1))    
    If SL1->(DbSeek(xFilial("SL1") + cNumOrc))
        //Monta cabeçalho do orçamento (SLQ)
        _aCab:= { {"LQ_VEND"    ,SL1->L1_VEND     ,NIL},;
                  {"LQ_COMIS"   ,SL1->L1_COMIS    ,NIL},;
                  {"LQ_CLIENTE" ,SL1->L1_CLIENTE  ,NIL},;
                  {"LQ_LOJA"    ,SL1->L1_LOJA     ,NIL},;
                  {"LQ_TIPOCLI" ,SL1->L1_TIPOCLI  ,NIL},;
                  {"LQ_VLRTOT"  ,SL1->L1_VLRTOT   ,NIL},;
                  {"LQ_DESCONT" ,SL1->L1_DESCONT  ,NIL},;
                  {"LQ_VLRLIQ"  ,SL1->L1_VLRLIQ   ,NIL},;
                  {"LQ_NROPCLI" ,SL1->L1_NROPCLI  ,NIL},;
                  {"LQ_DTLIM"   ,SL1->L1_DTLIM    ,NIL},;
                  {"LQ_DINHEIR" ,SL1->L1_DINHEIR  ,NIL},;
                  {"LQ_EMISSAO" ,dDataBase        ,NIL},;
                  {"LQ_NUMCFIS" ,SL1->L1_NUMCFIS  ,NIL},;
                  {"LQ_VLRDEBI" ,SL1->L1_VLRDEBI  ,NIL},;
                  {"LQ_HORA"    ,SL1->L1_HORA     ,NIL},;
                  {"LQ_NUMMOV"  ,SL1->L1_NUMMOV   ,NIL}}


        dbSelectArea("SL2")
        SL2->(dbSetOrder(1))
        If SL2->(DbSeek(xFilial("SL2") + SL1->L1_NUM))

            While !SL2->(Eof()) .And. xFilial("SL2") + SL1->L1_NUM == SL2->L2_FILIAL + SL2->L2_NUM            
                aAdd(_aItem,{ {"LR_PRODUTO" ,SL2->L2_PRODUTO,NIL},;
                              {"LR_QUANT"   ,SL2->L2_QUANT  ,NIL},;
                              {"LR_UM"      ,SL2->L2_UM     ,NIL},;
                              {"LR_DESC"    ,SL2->L2_DESC   ,NIL},;
                              {"LR_VALDESC" ,SL2->L2_VALDESC,NIL},;
                              {"LR_DOC"     ,SL2->L2_DOC    ,NIL},;
                              {"LR_SERIE"   ,SL2->L2_SERIE  ,NIL},;
                              {"LR_PDV"     ,SL2->L2_PDV    ,NIL},;
                              {"LR_TABELA"  ,SL2->L2_TABELA ,NIL},;
                              {"LR_DESCPRO" ,SL2->L2_DESCPRO,NIL},;
                              {"LR_FILIAL"  ,SL2->L2_FILIAL ,NIL},;
                              {"LR_VEND"    ,SL2->L2_VEND   ,NIL} })        
                SL2->(dbSkip())
            EndDo      
            
        EndIf

        dbSelectArea("SL4")
        SL4->(dbSetOrder(1))
        If SL4->(DbSeek(xFilial("SL4") + SL1->L1_NUM))
    
            While !SL4->(Eof()) .And. xFilial("SL4") + SL1->L1_NUM == SL4->L4_FILIAL + SL4->L4_NUM                     
                //Monta o cabeçalho do orçamento (aPagtos)
                aAdd(_aParcela,{{"L4_DATA"    ,SL4->L4_DATA     ,NIL},;
                                {"L4_VALOR"   ,SL4->L4_VALOR    ,NIL},;
                                {"L4_FORMA"   ,SL4->L4_FORMA    ,NIL},;
                                {"L4_ADMINIS" ,SL4->L4_ADMINIS  ,NIL},;
                                {"L4_FORMAID" ,SL4->L4_FORMAID  ,NIL},;
                                {"L4_MOEDA"   ,SL4->L4_MOEDA    ,NIL}})
                SL4->(dbSkip())
            EndDo  

        EndIf
    
        SetFunName("LOJA701")
        
        lMsHelpAuto := .T.
        lAutoErrNoFile  := .T.
        lMsErroAuto := .F.
		       		
        MSExecAuto({|a,b,c,d,e,f,g,h,i| Loja701(a,b,c,d,e,f,g,h,i)}, .F., nOpc, "", "", {}, _aCab, _aItem, _aParcela, .T.)

        If lMsErroAuto 
            MostraErro()
            aiErro := GetAutoGRLog()
            RollBackSX8()
        Else
            ConfirmSX8()
            FwAlertSucess("Sucesso na execução do ExecAuto")
            lRet := .T.
        EndIf
    EndIf

    RestArea(aArea)
    RestArea(aSL1Area)
    RestArea(aSL2Area)
    RestArea(aSL4Area)
    RestArea(aSX3Area)

Return lRet

