#INCLUDE 'TOTVS.CH'
#INCLUDE 'PROTHEUS.CH'
#include 'TBICONN.CH'

/*/{Protheus.doc} BxTit
ExecAuto de baixa do titulo a receber - FINA070.
@type function
@author Rivaldo Jr.
@since 25/08/2024
@param cNumTit, character, Numero do titulo.
@return variant, Retorna true se conseguir baixar.
/*/
User Function BxTit(cNumTit)
	Local aArea			:= GetArea()
	Local lOk       	:= .T.
	Local _aCabec 		:= {}
	Local aiErro 		:= {}
	Local aBanco 		:= {}
	Local cFilArq		:= ''
	Local cBanco  		:= ''
	Local cAgencia		:= ''
	Local cConta  		:= ''
	Private lMsErroAuto := .F.							// Tratamento de erro de rotina automatica
	Private lMsHelpAuto := .T.							// Tratamento de erro de rotina automatica
	Private lAutoErrNoFile := .T.						// Tratamento de erro de rotina automatica

    DbSelectArea('SE1')
    DbSelectArea('SA6')
	If SE1->(DbSetOrder(1),DbSeek(cfilant+"600"+cNumTit))
		cFilArq := cFilAnt
		cFilAnt := SE1->E1_FILIAL

		aBanco  := Separa(SuperGetMV("MV_XCBX",.F.,"CX1;000;000"),";",.T.)

		cBanco  := Padr(aBanco[1],TamSx3("A6_COD")[1])
		cAgencia:= Padr(aBanco[2],TamSx3("A6_AGENCIA")[1])
		cConta 	:= Padr(aBanco[3],TamSx3("A6_NUMCON")[1])

		If SA6->(DbSetOrder(1),DbSeek(xFilial("SA6")+cBanco+cAgencia+cConta))//-- PEGAR OS DADOS DO BANCO

			_aCabec :=	{{"E1_FILIAL"   , SE1->E1_FILIAL 	  , Nil},;
						{"E1_PREFIXO"   , SE1->E1_PREFIXO	  , Nil},;
						{"E1_NUM"       , SE1->E1_NUM    	  , Nil},;
						{"E1_TIPO"      , SE1->E1_TIPO   	  , Nil},;
						{"E1_PARCELA"   , SE1->E1_PARCELA	  , Nil},;
						{"AUTMOTBX"     , "NOR"       		  , Nil},;
						{"AUTBANCO"     , SA6->A6_COD         , Nil},;
						{"AUTAGENCIA"   , SA6->A6_AGENCIA     , Nil},;
						{"AUTCONTA"     , SA6->A6_NUMCON      , Nil},;
						{"AUTDTBAIXA"   , dDataBase	   		  , Nil},;
						{"AUTDTCREDITO" , dDataBase	   		  , Nil},;
						{"AUTHIST" 		, ""				  , Nil},;
						{"AUTJUROS"     , 0    				  , Nil},;
						{"AUTDESCONT"   , 0 				  , Nil},;
						{"AUTVALREC"    , SE1->E1_SALDO       , Nil}}
	
				MSExecAuto({|x,y| FINA070(x,y)},_aCabec,3) //3-Inclusao

				IF lMsErroAuto
					aiErro := GetAutoGRLog()
					CONOUT(aiErro[1])
					DisarmTransaction()
				Endif

		EndIf
    EndIf

	cfilant := cFilArq	
	RestArea(aArea)

Return lOk
