#Include 'TOTVS.CH'
#Include 'FWMVCDEF.ch'
#INCLUDE "SIGAWIN.CH"

/*/{Protheus.doc} ExpPed
Exporta um .CSV para importar
@type function
@author Rivaldo Jr.
@since 07/08/2024
/*/
User Function TelExpPed()
	Private oTempTCAB As Object
	Private oTempITEM As Object
	Private aCampos  := {}
	Private aCampos2 := {}
	Private aButtons := {{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.T.,"Confirmar"},;
		{.T.,"Cancelar"},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,Nil},;
		{.F.,NIl}}
	Private cTrimestre:= ''
	Private lAlt  := .F.

	//// -- Criação da tabela temporária
    aAdd(aCampos,{"T1_CLIENTE"  ,"C",TamSX3("A1_COD")[1]    ,0})
    aAdd(aCampos,{"T1_LOJA"     ,"C",TamSX3("A1_LOJA")[1]   ,0})
	aAdd(aCampos,{"T1_VEND" 	,"C",TamSX3("C5_VEND1"	)[1],0})
	aAdd(aCampos,{"T1_TAB"   	,"C",TamSX3("C5_TABELA"	)[1],0})
	aAdd(aCampos,{"T1_COND"     ,"C",TamSX3("C5_CONDNEG")[1],0})
	aAdd(aCampos,{"T1_CONDPAG"  ,"C",TamSX3("C5_CONDPAG")[1],0})
	aAdd(aCampos,{"T1_TIPOCLI"  ,"C",TamSX3("C5_TIPOCLI")[1],0})
	aAdd(aCampos,{"T1_TIPOPED"  ,"C",TamSX3("C5_TIPO"	)[1],0})
	
	//// --- Criar tabela temporária
	oTempTCAB := FWTemporaryTable():New("TCAB")
	oTempTCAB:SetFields(aCampos)
	oTempTCAB:AddIndex("01", {"T1_CLIENTE","T1_LOJA"})
	oTempTCAB:Create()

	//// -- Criação da tabela temporária
    aAdd(aCampos2,{"T1_ITEM"  ,"C",2    				 ,0})
    aAdd(aCampos2,{"T1_PROD"  ,"C",TamSX3("B1_COD")[1]   ,0})
	aAdd(aCampos2,{"T1_DESC"  ,"C",TamSX3("B1_DESC")[1]  ,0})
	aAdd(aCampos2,{"T1_QUANT" ,"N",TamSX3("C6_QTDVEN")[1],2})
	aAdd(aCampos2,{"T1_VALOR" ,"N",TamSX3("C6_PRCVEN")[1],2})
	aAdd(aCampos2,{"T1_TOTAL" ,"N",TamSX3("C6_VALOR")[1] ,2})

	//// --- Criar tabela temporária
	oTempITEM := FWTemporaryTable():New("ITEM")
	oTempITEM:SetFields(aCampos2)
	oTempITEM:AddIndex("01", {"T1_ITEM","T1_PROD"})
	oTempITEM:Create()

	FWExecView("Importação pedido de venda","TelExpPed",MODEL_OPERATION_INSERT,,{|oModel| .T./*AltXML(oModel)*/ },,60,aButtons,{ |oModel| Close(oModel)})

	oTempITEM:Delete()
Return

/*/{Protheus.doc} ViewDef
	Função para confirmar o cancelar da tela.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function Close(oModel)
	Local lRet  := .T.
	//Local oModel:= FWModelActive()
	Local oView := FWViewActive()
	Local oGrid := oModel:GetModel("DETXML")

	If oGrid:Length() > 1
		lRet := FwAlertYesNo("Você irá perder os dados preenchidos,"+CRLF+;
		"Tem certeza que deseja continuar?")
	EndIf
	If lRet
		oView:SetModified(.F.)
	EndIf
Return lRet

/*/{Protheus.doc} ViewDef
	Função que monta o model da tela.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function ModelDef()
	Local oModel
	Local oStrField := fn01MCAB()
	Local oStrGrid  := fn01MGrid()
	Local bCamValid := {|oModel, cAction, cIDField, xValue|  VldField(cAction, cIDField, xValue)}

	oModel := MPFormModel():New("MIDMAIN",,,)
	oModel:SetDescription("Cadastro de Metas e Verbas")
	oModel:AddFields("MSTCAB",,oStrField,bCamValid)
	oModel:AddGrid("DETXML","MSTCAB",oStrGrid,,,,,)
	oModel:AddCalc( 'CALC', 'MSTCAB', 'DETXML', 'T1_TOTAL', 'TOTALXX', 'SUM',{|| .T.}, {|| 0},'Total do pedido',,10,2 )

Return oModel

Static Function VldField(cAction, cIDField, xValue)
	Local lRet 	    := .T.
	Local nX 		:= 0
	Local nAtu 		:= 0
	Local nPrcUnit  := 0
	Local nQuant    := 0
	Local oModel    := FWModelActive()
	Local oView     := FwViewActive()
	Local oGrid     := oModel:GetModel("DETXML")

	If cAction == "SETVALUE" .AND. xValue <> NIL .AND. cIDField == "T1_TAB"
		If oGrid:Length() > 0 .And. xValue <> M->T1_TAB
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1))
			For nX := 1 To oGrid:Length()
				oGrid:GoLine(nX)
				If SB1->(DbSeek(xFilial("SB1")+oGrid:GetValue("T1_PROD")))
					nPrcUnit := Posicione("DA1",1,xFilial("DA1")+xValue+SB1->B1_COD,"DA1_PRCVEN")
					nQuant   := oGrid:GetValue("T1_QUANT")
					oGrid:LoadValue("T1_VALOR", nPrcUnit				   )
					oGrid:LoadValue("T1_TOTAL", Round(nQuant*nPrcUnit,2))
					nAtu++
				EndIf
			Next
		EndIf
		If nAtu > 0
			FwAlertWarning("Os preços dos produtos foram atualizados de acordo com a tabela selecionada.","ATENÇÃO!")
			oView:Refresh('FDET')
			oGrid:GoLine(1)
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} ViewDef
	Função que monta a estrutura dos campos do cabeçalho da tela.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function fn01MCAB()
	Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("TCAB",{"T1_CLIENTE","T1_LOJA"},"PEDIDO")
	oStruct:AddField("CLIENTE" 	   	,"CLIENTE" 	  	,"T1_CLIENTE"  ,"C",TamSX3("A1_COD")[1]    ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("LOJA" 	   	,"LOJA" 	  	,"T1_LOJA"     ,"C",TamSX3("A1_LOJA")[1]   ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("VENDEDOR"   	,"VENDEDOR"   	,"T1_VEND" 	   ,"C",TamSX3("C5_VEND1")[1]  ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("TABELA"	  	,"TABELA"	  	,"T1_TAB" 	   ,"C",3  					   ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("COND. NEGOCIA","COND. NEGOCIA","T1_COND"     ,"C",TamSX3("C5_CONDNEG")[1],0,Nil,Nil,{},.T.,{|| "N"},.F.,.F.,.F.)
	oStruct:AddField("COND. PAGTO"  ,"COND. PAGTO"  ,"T1_CONDPAG"  ,"C",TamSX3("C5_CONDPAG")[1],0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("TIPO CLIENTE" ,"TIPO CLIENTE" ,"T1_TIPOCLI"  ,"C",TamSX3("C5_TIPOCLI")[1],0,Nil,Nil,{},.T.,{|| "F"},.F.,.F.,.F.)
	oStruct:AddField("TIPO PEDIDO"  ,"TIPO PEDIDO"  ,"T1_TIPOPED"  ,"C",TamSX3("C5_TIPO")[1]   ,0,Nil,Nil,{},.T.,{|| "N"},.F.,.F.,.F.)

Return oStruct

/*/{Protheus.doc} ViewDef
	Função que monta a estrutura dos campos da grid.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function fn01MGrid()
	Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("ITEM",{"T1_ITEM","T1_PROD"},"ITENS")
	oStruct:AddField("ITEM" 	   ,"ITEM" 		  ,"T1_ITEM"  ,"C",2					  ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("PRODUTO" 	   ,"PRODUTO" 	  ,"T1_PROD"  ,"C",TamSX3("B1_COD")[1]    ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("DESCRICAO"   ,"DESCRICAO"   ,"T1_DESC"  ,"C",TamSX3("B1_DESC")[1]   ,0,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("QUANTIDADE"  ,"QUANTIDADE"  ,"T1_QUANT" ,"N",TamSX3("C6_QTDVEN")[1] ,2,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("PRECO UNIT"  ,"PRECO UNIT"  ,"T1_VALOR" ,"N",TamSX3("C6_PRCVEN")[1] ,2,Nil,Nil,{},.T.,,.F.,.F.,.F.)
	oStruct:AddField("VALOR TOTAL" ,"VALOR TOTAL" ,"T1_TOTAL" ,"N",TamSX3("C6_VALOR")[1]  ,2,Nil,Nil,{},.T.,,.F.,.F.,.F.)

Return oStruct

/*/{Protheus.doc} ViewDef
	Função que monta a view da tela.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function ViewDef()
	Local oModel  	:= ModelDef()
	local oStrField := FWFormViewStruct():New()
	Local oStrGrid  := FWFormViewStruct():New()
	Local oView     As Object
	Local oCalc1    As Object

	oStrField:AddField("T1_CLIENTE" ,"00","Cliente"     ,"Cliente"     ,Nil,"C",X3Picture("A1_COD")    ,Nil,"SA1",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrField:AddField("T1_LOJA" 	,"01","Loja"        ,"Loja"        ,Nil,"C",X3Picture("A1_LOJA")   ,Nil,""   ,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrField:AddField("T1_VEND"    ,"02","Vendedor 1"  ,"Vendedor 1"  ,Nil,"C",X3Picture("C5_VEND1")  ,Nil,"SA3",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrField:AddField("T1_TAB"	    ,"03","Tabela"      ,"Tabela"      ,Nil,"C","@!" 				   ,Nil,"DA0",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrField:AddField("T1_COND"    ,"04","Cond.Negocia","Cond.Negocia",Nil,"C",X3Picture("C5_CONDNEG"),Nil,""   ,.T.,Nil,Nil,Separa(GetSX3Cache('C5_CONDNEG','X3_CBOX'),";"),Nil,"N",.F.,Nil,Nil)
	oStrField:AddField("T1_CONDPAG" ,"05","Cond. Pagto" ,"Cond. Pagto" ,Nil,"C",X3Picture("C5_CONDPAG"),Nil,"SE4",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrField:AddField("T1_TIPOCLI" ,"06","Tipo Cliente","Tipo Cliente",Nil,"C",X3Picture("C5_TIPOCLI"),Nil,""   ,.T.,Nil,Nil,Separa(GetSX3Cache('C5_TIPOCLI','X3_CBOX'),";"),Nil,"F",.F.,Nil,Nil)
	oStrField:AddField("T1_TIPOPED" ,"07","Tipo Pedido" ,"Tipo Pedido" ,Nil,"C",X3Picture("C5_TIPO")   ,Nil,""   ,.T.,Nil,Nil,Separa(GetSX3Cache('C5_TIPO','X3_CBOX'),";"),Nil,"N",.F.,Nil,Nil)

	oStrGrid:AddField("T1_ITEM" 	,"00","Item"        ,"Item"        ,Nil,"C","@!"				   ,Nil,""	,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrGrid:AddField("T1_PROD" 	,"01","Produto"     ,"Produto"     ,Nil,"C",X3Picture("B1_COD")    ,Nil,""	,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrGrid:AddField("T1_DESC" 	,"02","Descricao"   ,"Descricao"   ,Nil,"C",X3Picture("B1_DESC")   ,Nil,""	,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrGrid:AddField("T1_QUANT"	,"03","Quantidade"  ,"Quantidade"  ,Nil,"N",X3Picture("C6_QTDVEN") ,Nil,""	,.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrGrid:AddField("T1_VALOR"	,"04","Prc Unitario","Prc Unitario",Nil,"N",X3Picture("C6_PRCVEN") ,Nil,""	,.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStrGrid:AddField("T1_TOTAL"	,"05","Vlr.Total"   ,"Vlr.Total"   ,Nil,"N",X3Picture("C6_VALOR")  ,Nil,""	,.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("FFIL",oStrField,"MSTCAB")
	oView:AddGrid("FDET",oStrGrid,"DETXML")
	oCalc1 := FWCalcStruct( oModel:GetModel( 'CALC') )
	oView:AddField( 'VIEW_CALC', oCalc1, 'CALC' )

	// --- Definição da Tela
	oView:CreateHorizontalBox("BXFIL",30)
	oView:CreateHorizontalBox("BXREG",60)
	oView:CreateHorizontalBox("BXROD",10)
	oView:AddUserButton("Exportar .CSV","MAGIC_BMP",{|oView| U_ExpCSV()},"Exportar .CSV", , , .T.)
	oView:AddUserButton("Importar .CSV","MAGIC_BMP",{|oView| U_ImpCSV()},"Importar .CSV", , , .T.)

	oView:SetOwnerView("FFIL","BXFIL")
	oView:SetOwnerView("FDET","BXREG")
	oView:SetOwnerView("VIEW_CALC","BXROD")

	//Força o fechamento da janela na confirmação
	oView:SetCloseOnOk({||.T.})

	oView:AddIncrementField('FDET', 'T1_ITEM')

Return oView

/*/{Protheus.doc} ImpCSV
	Função que monta a tela para selecionar o arquivo .CSV .
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
User Function ImpCSV()
	Local cCaminho := ""
	Local cDirIni  := "C:/"
	Local aRes     := {}
	Local oModel   := FWModelActive()
	Local oCab     := oModel:GetModel("MSTCAB")
	Private cFile  := ""

	If Empty(oCab:GetValue("T1_TAB"))
		Help(" ",1,"ATENÇÃO!",,"Tabela de preço não definida.";
		,3,1,,,,,,{"Defina a tabela de preço para que o grid traga as informações corretamente."})
		Return
	EndIf

	DEFINE MSDIALOG oDlg TITLE "Importação CSV" From 0,0 To 15,50

	oSayArq := tSay():New(15,07,{|| "Este programa tem como objetivo a importação de dados, onde os mesmos serão importados e diretamente alterados "+;
		"de um arquivo no formato CSV"+;
		"(Valores Separados por 'Ponto e Vírgula')."},oDlg,,,,,,.T.,,,200,80)

	oSayArq := tSay():New(45,07,{|| "Informe o local onde se encontra o arquivo para importação:"},oDlg,,,,,,.T.,,,200,80)
	oGetArq := TGet():New(55,05,{|u| If(PCount()>0,cCaminho:=u,cCaminho)},oDlg,150,10,'@!',,,,,,,.T.,,,,,,,,,,'cCaminho')

	oBtnArq := tButton():New(55,160,"Abrir...",oDlg,{|| cCaminho := cGetFile( "Arquivos CSV|*.csv|Arquivos CSV|*.csv", "Selecione o arquivo:",  1, cDirIni, .F., GETF_LOCALHARD,.F., )},30,12,,,,.T.)
	oBtnImp := tButton():New(80,050,"Importar",oDlg,{|| aRes := ImpTvInc(cCaminho) },40,12,,,,.T.)
	oBtnCan := tButton():New(80,110,"Cancelar",oDlg,{|| oDlg:End()},40,12,,,,.T.)

	ACTIVATE MSDIALOG oDlg CENTERED

	//FWMsgRun(, {|| GerCSV() }, "Processando", "Gerando CSV...")

Return 

/*/{Protheus.doc} ExpCSV
	Função para gerar o parambox e pegar o caminho onde será salvo o arquivo.
	@type  Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
User Function ExpCSV()
	Private cCaminho  := ""//"l:\users\rivaldojr\downloads\"
	Private aPergs := {}

	aAdd( aPergs ,{1,"Produto: ", space(TamSX3("B4_COD")[1]),"@!",'.T.','SB4','.T.',TamSX3("B4_COD")[1]+50,.T.})//MV_PAR01

	If !ParamBox(aPergs ,"Informe os parâmetros")
		Return
	EndIf
	
	cCaminho    := cGetFile("Todos os arquivos|.",; 		//[ cMascara],
	OemToAnsi("Selecione o caminho para salvar o arquivo"),;//[ cTitulo],
	0,;														//[ nMascpadrao],
	"\",;													//[ cDirinicial],
	.F.,;													//[ lSalvar],
	GETF_LOCALHARD,.F., )										//[ nOpcoes],
	cCaminho := SubStr(cCaminho,1,RAt('\',cCaminho))

	If Empty(cCaminho)
		Return
	EndIf

	FWMsgRun(, {|| GerCSV() }, "Processando", "Exportando estrutura do produto...")

Return 

/*/{Protheus.doc} GerCSV
	Função para gerar arquivo .CSV com a estrutura do produto.
	@type Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function GerCSV()
	Local cQuebra  := Chr(13)+Chr(10)
	Local nColuns  := 1
	Local nArquivo := 0
	Local nHandle  := 0
	Local cQuery   := ""
	Local cProduto := SubStr(AllTrim(MV_PAR01),1,11)
	Local cQuerySB4:= GetNextAlias()
	Local cQuerySBV:= GetNextAlias()
	Local cBuffer  := ""
	Local cDescProd:= ""

	// PARA BUSCAR AS COLUNAS
	cQuery := "	SELECT BV_DESCRI, B4_DESC FROM "+RetSqlName("SB4")+" SB4 "+cQuebra
	cQuery += "	INNER JOIN "+RetSqlName("SBV")+" SBV ON BV_FILIAL = B4_FILIAL AND BV_TABELA = B4_COLUNA "+cQuebra
	cQuery += "	WHERE B4_COD LIKE '%"+cProduto+"%' "+cQuebra
	cQuery += "	AND B4_FILIAL = '"+xFilial("SB4")+"' "+cQuebra
	cQuery += "	AND SB4.D_E_L_E_T_ ='' "+cQuebra
	MpSysOpenQuery(cQuery, cQuerySB4)

	If (cQuerySB4)->(Eof())
		FwAlertWarning("Produto sem estrutura cadastrada.","Atenção!")
		Return
	EndIf

	cDescProd := AllTrim((cQuerySB4)->B4_DESC)

	nArquivo := cCaminho+cDescProd+"-"+Time()+".CSV"
	nHandle := fcreate(nArquivo)
	If nHandle == -1
		FwAlertWarning("Não foi possivel criar o arquivo.","Atenção!")
		Return 
	EndIf

	cBuffer := cProduto+" IMPORTACAO DO PRODUTO "+Upper(cDescProd)+cQuebra

	cBuffer += "X;"
	While (cQuerySB4)->(!Eof())
		nColuns++
		cBuffer += StrTran(Transform(val(AllTrim((cQuerySB4)->BV_DESCRI))/100, "@E 999.99"),',','.')
		(cQuerySB4)->(DbSkip())
		cBuffer += iIf((cQuerySB4)->(Eof()),cQuebra,";")
	End

	// PARA BUSCAR AS LINHAS
	cQuery := "	SELECT BV_DESCRI FROM "+RetSqlName("SB4")+" SB4 "+cQuebra
	cQuery += "	INNER JOIN "+RetSqlName("SBV")+" SBV ON BV_FILIAL = B4_FILIAL AND BV_TABELA = B4_LINHA "+cQuebra
	cQuery += "	WHERE B4_COD LIKE '%"+cProduto+"%' "+cQuebra
	cQuery += "	AND B4_FILIAL = '"+xFilial("SB4")+"' "+cQuebra
	cQuery += "	AND SB4.D_E_L_E_T_ ='' "+cQuebra
	MpSysOpenQuery(cQuery, cQuerySBV)

	While (cQuerySBV)->(!Eof())
		cBuffer += StrTran(Transform(val(AllTrim((cQuerySBV)->BV_DESCRI))/100, "@E 999.99"),',','.')+Replicate(";",nColuns)+cQuebra
		(cQuerySBV)->(DbSkip())
	End

	FWrite(nHandle, cBuffer)
	fclose(nHandle)
	FwAlertSucess("Arquivo gerado com sucesso.","Atenção!")

	If cValToCHar(GetRemoteType()) $ '0|1' //Abrir apenas no Windows
		oExcelApp := MsExcel():New()
		oExcelApp:WorkBooks:Open( cCaminho+cProduto+".CSV" ) // Abre uma planilha
		oExcelApp:SetVisible(.T.)
	EndIf

	(cQuerySB4)->(DbCloseArea())
	(cQuerySBV)->(DbCloseArea())
Return 

/*/{Protheus.doc} GerCSV
	Função para importar o arquivo .CSV com a estrutura do produto.
	@type Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function ImpTvInc(cCaminho)
	Local oProcess  := nil
	Local aRes      := nil
	Default cIdPlan := "1"
	Default cArq    := ""
	Default cDelimiter := ";"

	If Empty(cCaminho)
		MsgInfo("Selecione um arquivo",)
		Return
	ElseIf !File(cCaminho)
		MsgInfo("Arquivo não localizado","Atenção")
		Return
	Else
		oDlg:End()
		oProcess := MsNewProcess():New({|lEnd| aRes:= ProcessCSV(cCaminho,@oProcess)  },"Extraindo dados da planilha CSV","Efetuando a leitura do arquivo CSV...", .T.)
		oProcess:Activate()
	EndIf

Return aRes

/*/{Protheus.doc} GerCSV
	Função para realiza o processamento do arquivo .CSV com a estrutura do produto.
	@type Function
	@author Rivaldo Jr. 
	@since 07/08/2024
/*/
Static Function ProcessCSV(cCaminho,oProcess)
	Local nX, nY
	Local cMsgHead  	:= "ICsvNat()"
	Local cLProd 		:= ""
	Local cCProd 		:= ""
	Local cProd  		:= ""
	Local cErro  		:= ""
	Local aRes     		:= {}
	Local aLines  		:= {}
	Local aLinha    	:= {}
	Local lManterVazio 	:= .T.
	Local lEnd         	:= .F.
	Local nQuant 		:= 0
	Local nPrcUnit 		:= 0
	Local oFile     	As Object
	Private oModel      := FWModelActive()
	Private oCab 		:= oModel:GetModel("MSTCAB")
	Private oGrid 		:= oModel:GetModel("DETXML")
	Private lMsErroAuto := .F.
	Private oTable		As Object

	oFile := FWFileReader():New(cCaminho)
	If !oFile:Open()
		ApMsgStop("Não foi possvel efetuar a leitura do arquivo." + cArq, cMsgHead)
		Return aRes
	EndIf
	aLines := oFile:GetAllLines()

	If lEnd   //VERIFICAR SE NO CLICOU NO BOTAO CANCELAR
		ApMsgStop("Processo cancelado pelo usuário." + cArq, cMsgHead)
		Return aRes
	EndIf

	oProcess:IncRegua1("3/4 Ler Arquivo CSV")
	oProcess:SetRegua2(Len(aLines))

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1))

	For nX:=3 to len(aLines)
		oProcess:SetRegua2(nX)
		cProd := SubStr(aLines[1],1,TamSX3("B1_COD")[1]-4)
		if lEnd   //VERIFICAR SE NO CLICOU NO BOTAO CANCELAR
			ApMsgStop("Processo cancelado pelo usuário." + cArq, cMsgHead)
			Return {}
		EndIf
		cLinha  := aLines[nX]
		If !Empty(cLinha)
			cLinha := StrTran(StrTran(cLinha, '"', ''), ",", ".")
			aLinha := Separa(cLinha, cDelimiter, lManterVazio)
			If Len(aLinha) > 0

				For nY := 2 To Len(aLinha)
					If !Empty(aLinha[nY])
						cLProd := StrZero(nX-2, TamSX3("B4_LINHA")[1]) 
						cCProd := StrZero(nY-1, TamSX3("B4_COLUNA")[1])
						nQuant := Val(aLinha[nY])
						cProd  := Padr(cProd+cLProd+cCProd, TamSX3("B1_COD")[1])
						If SB1->(DbSeek(xFilial("SB1")+cProd))
							oGrid:GoLine(oGrid:Length())
							While !Empty(oGrid:GetValue("T1_PROD"))
								oGrid:AddLine()
								oGrid:GoLine(oGrid:Length())
							End
							nPrcUnit := Posicione("DA1",1,xFilial("DA1")+oCab:GetValue("T1_TAB")+SB1->B1_COD, "DA1_PRCVEN")
							If nPrcUnit == 0 
								cErro += "Produto "+cProd+" está sem preço na tabela "+oCab:GetValue("T1_TAB")+" Por favor, ajustar!"+CRLF+CRLF
								Loop
							EndIf
							oGrid:SetValue("T1_ITEM" , StrZero(oGrid:Length(),2))
							oGrid:SetValue("T1_PROD" , AllTrim(SB1->B1_COD)    )
							oGrid:SetValue("T1_DESC" , AllTrim(SB1->B1_DESC)   )
							oGrid:SetValue("T1_QUANT", nQuant				   )
							oGrid:SetValue("T1_VALOR", nPrcUnit				   )
							oGrid:SetValue("T1_TOTAL", Round(nQuant*nPrcUnit,2))
						EndIf
					EndIf
				Next

			EndIf
		EndIf
	Next
	oGrid:GoLine(1)

	oFile:Close()
	oProcess:IncRegua1("4/4 Remove temporarios")
	oProcess:SetRegua2(1)
	oProcess:IncRegua2("")

	If !Empty(cErro)
		Help(" ",1,"ATENÇÃO!",,cErro;
		,3,1,,,,,,{""})
	Else 
		FwAlertSucess("Importação de itens concluída.","Sucesso!")
	EndIf

Return aRes
