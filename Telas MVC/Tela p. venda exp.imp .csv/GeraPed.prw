#Include 'TOTVS.CH'

/*/{Protheus.doc} MIDMAIN
Ponto de entrada da tela MVC, chama a função para gerar pedido de venda.
@type function
@author Rivaldo Jr. 
@since 07/08/2024
/*/
User Function MIDMAIN()
	Local aParam     := PARAMIXB
	Local lRet 		 := .T.
	Local oModel     := aParam[1]
	Local cIdPonto   := aParam[2]

	If cIdPonto == 'MODELCOMMITNTTS'
		FWMsgRun(, {|| lRet := GeraPed(oModel) }, "Aguarde", "Gerando pedido de venda...")
	EndIf

Return lRet

/*/{Protheus.doc} GeraPed
Função para gerar pedido de venda.
@type function
@author Rivaldo Jr. 
@since 07/08/2024
/*/
Static Function GeraPed(oModel)
	Local aArea			:= GetArea()
	Local oModelCab     := oModel:GetModel("MSTCAB")
	Local oModelGrid    := oModel:GetModel("DETXML")
	Local aCabPv  		:= {}
	Local aItePv  		:= {}
	Local aIteTp		:= {}
	Local aiErro		:= {}
	Local cNumPed 		:= ''
	Local cProd			:= ''
    Local cDesc         := ''
    Local cUm           := ''
    Local ciErro        := ''
	Local lOK           := .F.
	Local nPrcVen,nX,nQuant,sX:= 0
	Private lMsErroAuto := .F.
	Private lAutoErrNoFile := .T.

	cNumPed := GetSXEnum("SC5","C5_NUM")
	While SC5->(DbSeek(xFilial("SC5")+cNumPed))
		ConfirmSX8()
		cNumPed := GetSXEnum("SC5","C5_NUM")
	End

	**/*TABELA SC5 CABEÇALHO DO PEDIDO DE VENDA*/**
	aAdd(aCabPv,{"C5_FILIAL"  	, cFilant									,Nil}) 
	aAdd(aCabPv,{"C5_NUM"     	, cNumPed			   						,Nil}) 
	aAdd(aCabPv,{"C5_CLIENTE"	, oModelCab:GetValue("T1_CLIENTE")			,Nil}) 
	aAdd(aCabPv,{"C5_LOJACLI"	, oModelCab:GetValue("T1_LOJA")				,Nil}) 
	aAdd(aCabPv,{"C5_TIPO"		, oModelCab:GetValue("T1_TIPOPED")			,Nil})
	aAdd(aCabPv,{"C5_VEND1"		, oModelCab:GetValue("T1_VEND")				,Nil})
	aAdd(aCabPv,{"C5_TABELA"	, oModelCab:GetValue("T1_TAB")				,Nil})
	aAdd(aCabPv,{"C5_CONDNEG"	, oModelCab:GetValue("T1_COND")				,Nil})
	aAdd(aCabPv,{"C5_CONDPAG"	, oModelCab:GetValue("T1_CONDPAG")			,Nil})
	aAdd(aCabPv,{"C5_TIPOCLI"	, oModelCab:GetValue("T1_TIPOCLI")			,Nil})
	aAdd(aCabPv,{"C5_EMISSAO" 	, dDataBase									,Nil}) 
	aAdd(aCabPv,{"C5_MOEDA" 	, 1											,Nil}) 

	For nX:= 1 To oModelGrid:Length()
		oModelGrid:GoLine(nX)
		aItePv := {}

		cProd   := Padr(oModelGrid:GetValue("T1_PROD")					 ,TamSX3("B1_COD")[1])
        cDesc   := Padr(Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC"),TamSX3("C6_DESCRI")[1])
        cUm     := Padr(Posicione("SB1",1,xFilial("SB1")+cProd,"B1_UM")  ,TamSX3("C6_UM")[1])
		nQuant  := oModelGrid:GetValue("T1_QUANT")
		nPrcVen := oModelGrid:GetValue("T1_VALOR")
		
		**/*TABELA SC6 ITENS DO PEDIDO DE VENDA*/**
		aAdd(aItePv,{"C6_FILIAL"  	,cFilant								,Nil})
		aAdd(aItePv,{"C6_ITEM"   	,StrZero(nX,TamSX3("C6_ITEM")[1])		,Nil})
		aAdd(aItePv,{"C6_PRODUTO"	,cProd									,Nil})
		aAdd(aItePv,{"C6_DESCRI"	,cDesc                                  ,Nil})
		aAdd(aItePv,{"C6_QTDVEN"  	,nQuant									,Nil})
		aAdd(aItePv,{"C6_PRUNIT"  	,nPrcVen								,Nil})
		aAdd(aItePv,{"C6_VALOR"   	,Round(nQuant*nPrcVen,2)				,Nil})
		aAdd(aItePv,{"C6_UM"      	,cUm                                    ,Nil})
		aAdd(aItePv,{"C6_OPER"    	,"01"									,Nil})
		aAdd(aIteTp,aClone(aItePv))
		
	Next

	MsExecAuto({|x,y,z| mata410(x,y,z)},aCabPv,aIteTp,3)
	
	If lMsErroAuto
		aiErro	 := GetAutoGRLog()
		DisarmTransaction()
		RollBackSx8()
		For sX:=1 To Len(aiErro)
			ciErro += aiErro[sX] + Chr(13)+Chr(10)
		Next sX
		Help(" ",1,"ATENÇÃO!",,ciErro;
		,3,1,,,,,,{""})
	Else
		lOK := .T.
		ConfirmSX8()
		FwAlertSucess("Pedido de venda gerado com sucesso: "+SC5->C5_NUM,"Atenção!")
	EndIf
	RestArea(aArea)

Return lOK
