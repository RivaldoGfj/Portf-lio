#Include 'Protheus.ch'
#include "Totvs.CH"

/*/{Protheus.doc} DefLote
Rotina para definir lote para os produtos.
@type function
@author Rivaldo Jr.
@since 03/04/2023
@return variant, Retorna true se deu certo.
/*/
User Function DefLote()
  Local aArea  := GetArea()
  Local lRet   := .F.
  Local aLotes := {}
  Local cQuery := ''
  Local cDoc   := ''
  Local cLocCQ := ''
  Local cLoteCQ:= ''
  Private lMsErroAuto := .T.

  cLocCQ := GetMv("MV_CQ") // Armazém 02
  cLoteCQ:= GetMv("MV_XLOTECQ")

  //Query para buscar os produtos no armazém do CQ que estão sem movimento a mais de N dias.
  cQuery := " SELECT D7_PRODUTO, D7_LOCAL      "+CRLF
  cQuery += " FROM "+RetSqlName("SD7")+" SD7   "+CRLF
  cQuery += " WHERE SD7.D_E_L_E_T_ = ''        "+CRLF
  cQuery += " AND D7_LOCAL = "+cLocCQ+"        "+CRLF
  cQuery += " AND D7_LOTECTL = ''              "+CRLF
  cQuery += " AND D7_DATA < "+dDataBase+"      "+CRLF
  cQuery += " GROUP BY D7_PRODUTO, D7_LOCAL    "+CRLF
  cQuery += " ORDER BY D7_PRODUTO              "+CRLF
  MpSysOpenQuery(cQuery, "cQuery")

  cDoc := StrZero( 0, TamSX3("D5_DOC")[1] )

  DbSelectArea("SB2")
  SB2->(DbSetOrder(1))

  While cQuery->(!Eof())

      If SB2->(MsSeek(xFilial("SB2")+cQuery->(D7_PRODUTO+D7_LOCAL)))

        cDoc := Soma1(cDoc)
        aLotes := {}

        aAdd(aLotes, {	{"D5_DOC"		  , cDoc				        , Nil} ,;
                        {"D5_PRODUTO"	, SB2->B2_COD         , NIL} ,;
                        {"D5_LOCAL"		, SB2->B2_LOCAL	      , NIL} ,;
                        {"D5_DATA"		, dDataBase     	    , NIL} ,;
                        {"D5_QUANT"		, SB2->B2_QATU        , NIL} ,;
                        {"D5_LOTECTL"	, cLoteCQ	            , NIL} ,;
                        {"D5_DTVALID"	, DaySum(dDataBase,30), NIL} })
                        
        // Inclusao da movimentacao na SD5 - Criacao dos lotes //
        MSExecAuto({|x,y| Mata390(x,y)}, aLotes, 3)
      		
        If lMsErroAuto
          MostraErro()
          lRet := .F.
        Endif

      EndIf

      cQuery->(DbSkip())
  EndDo
  cQuery->(dbCloseArea())

  RestArea(aArea)

Return lRet
