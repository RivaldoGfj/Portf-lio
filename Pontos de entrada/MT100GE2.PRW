#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'PARMTYPE.CH'

/*/{Protheus.doc} MT100GE2
Complementa a Gravação dos Títulos Financeiros a Pagar.
Levar o centro de custo para o titulo.
@type function
@author Rivaldo Jr.
@since 22/05/2024
/*/
User Function MT100GE2()
    Local aArea    := GetArea()
    Local aAreaSD1 := SD1->(GetArea())
     
    If (INCLUI .OR. ALTERA)
        DbSelectArea('SE2')
        DbSelectArea('SD1')
        SD1->(DbSetOrder(1))
        SD1->(DbGoTop())
        
        //Posiciona no primeiro item do documento de entrada
        If SD1->(DbSeek(FWxFilial("SD1") + SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))
            SE2->(RecLock("SE2", .F.))
                SE2->E2_CCUSTO 	:= SD1->D1_CC
            SE2->(MsUnLock())
        EndIf
    EndIf
  
    RestArea(aAreaSD1)
    RestArea(aArea)
Return
