#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"
#Include "TOPCONN.ch"

/*/{Protheus.doc} TCadMeV
TELA MVC PARA CADASTRO DAS METAS E VERBAS NA X4
@type function
@author Rivaldo Jr.
@since 16/02/2023
/*/
User Function TCadMeV() 
	Local nX 		 := 0
	Private aCampos  := {}
	Private aCampos2  := {}
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
	Private aDivisao  := {"AGRICOLA","FERTILIZANTE","SEMENTES","ATACADO","PASTAGEM","VETERINÁRIA","BAYER PCO","PEÇAS JACTO"}
	Private aNDivisao := {"1","6","8","2","7","3","4","5"}
	Private cTrimestre:= ''
	Private lAlt  := .F.

	//// -- Criação da tabela temporária
	aAdd(aCampos,{"T1_ITEM"   ,"N",1,0})
	aAdd(aCampos,{"T1_NDIVI"  ,"C",1,0})
	aAdd(aCampos,{"T1_DIVISAO","C",12,0})
	aAdd(aCampos,{"T1_METAMES","N",12,2})
	aAdd(aCampos,{"T1_METATRI","N",12,2})
	aAdd(aCampos,{"T1_VERBA"  ,"N",12,2})
	aAdd(aCampos,{"T1_PERCEN" ,"N",20,0})
	
	//// --- Criar tabela temporária
	oTempTCAB := FWTemporaryTable():New("TCAB")
	oTempTCAB:SetFields(aCampos)
	oTempTCAB:AddIndex("01", {"T1_ITEM"})
	oTempTCAB:Create()

	DbSelectArea("TCAB")
	for nx:=1 to len(aDivisao)
		TCAB->(RecLock("TCAB",.T.))
			TCAB->T1_ITEM    := nX
			TCAB->T1_NDIVI   := aNDivisao[nX]
			TCAB->T1_DIVISAO := aDivisao[nX]
			TCAB->T1_METAMES := 0
			TCAB->T1_METATRI := 0
			TCAB->T1_VERBA   := 0
			TCAB->T1_PERCEN  := 0
		TCAB->(MsUnLock())
		TCAB->(DbSkip())
	next

	Do Case
		Case Month(Date()) >= 1 .And. Month(Date()) <= 3
			cTrimestre := "1º TRIMESTRE / "
		Case Month(Date()) > 3 .And. Month(Date()) <= 6
			cTrimestre := "2º TRIMESTRE / "
		Case Month(Date()) > 6 .And. Month(Date()) <= 9
			cTrimestre := "3º TRIMESTRE / "
		Case Month(Date()) > 9 .And. Month(Date()) <= 12
			cTrimestre := "4º TRIMESTRE / "
	EndCase

	FWExecView("Cadastro de Metas e Verbas - ( "+cTrimestre+cValToChar(Year(Date()))+" )","TCadMeV",MODEL_OPERATION_INSERT,,{|| .T.},,68,aButtons,{ |oModel| Close(oModel)})

	oTempTCAB:Delete()
Return


Static Function ModelDef()
	Local oModel
	Local oStrField:= FWFormModelStruct():New()
	Local oFilho   := fn01MCAB()

	// Estrutura Fake de Field
	oStrField:addTable("", {"C_STRING1"}, "Grid MVC sem cabeçalho", {|| ""})
	oStrField:addField("String 01", "Campo de texto", "C_STRING1", "C", 15)

	// --- Trigger
	oFilho:AddTrigger("T1_METATRI","T1_METAMES",{||.T.},{|oModelo| (FWFldGet("T1_METATRI")/3)})
	oFilho:AddTrigger("T1_VERBA","T1_PERCEN",{||.T.},{|oModelo| FWFldGet("T1_VERBA")/(FWFldGet("T1_METAMES")/100)})
	oFilho:AddTrigger("T1_METATRI","T1_PERCEN",{||.T.},{|oModelo| FWFldGet("T1_VERBA")/(FWFldGet("T1_METAMES")/100)})

	oModel := MPFormModel():New("MIDMAIN",,,{|oModel| Grava(oModel)})
	oModel:SetDescription("Cadastro de Metas e Verbas")
	oModel:AddFields("MSTCAB",,oStrField)
	oModel:AddGrid("DETSZ3","MSTCAB",oFilho,,, , ,{|oModel| loadGrid(oModel)})

 	oModel:AddCalc( 'COMP022CALC1', 'MSTCAB', 'DETSZ3', 'T1_METAMES', 'ZA2__TOT01', 'SUM',{|| .T.}, {|| 0},'Total Mensal',,10,2 )
	oModel:AddCalc( 'COMP022CALC1', 'MSTCAB', 'DETSZ3', 'T1_METATRI', 'ZA2__TOT02', 'SUM',{|| .T.}, {|| 0},'Total Trimestral',,10,2 )
	oModel:AddCalc( 'COMP022CALC1', 'MSTCAB', 'DETSZ3', 'T1_VERBA'  , 'ZA2__TOT03', 'SUM',{|| .T.}, {|| 0},'Total Verba',,10,2 )
	oModel:AddCalc( 'COMP022CALC1', 'MSTCAB', 'DETSZ3', 'T1_PERCEN' , 'ZA2__TOT04', 'FORMULA',{|| .T.},{|| 0},'Total Percentual',;
	{|oModel| oModel:GetModel("COMP022CALC1"):GetValue("ZA2__TOT03")/(oModel:GetModel("COMP022CALC1"):GetValue("ZA2__TOT01")/100)},10,2 )

	oModel:GetModel("DETSZ3"):SetMaxLine(8)
	oModel:GetModel("DETSZ3"):SetForceLoad(.T.)
	oModel:GetModel("DETSZ3"):SetNoInsertLine(.T.)
	oModel:GetModel("DETSZ3"):SetNoDeleteLine(.T.)

	oModel:GetModel("COMP022CALC1"):SetDescription("T.T. GERAL")

	// É necessário que haja alguma alteração na estrutura Field
	oModel:setActivate({ |oModel| onActivate(oModel)})
Return oModel

Static Function fn01MCAB()
	Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("TCAB",{"T1_ITEM"},"ITEM")
	oStruct:AddField("NDIVISAO"       ,"NDIVISAO"       ,"T1_NDIVI"  ,"C",1,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("DIVISAO"     	  ,"DIVISAO"        ,"T1_DIVISAO","C",20,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("META MENSAL"    ,"META MENSAL"    ,"T1_METAMES","N",15,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("META TRIMESTRAL","META TRIMESTRAL","T1_METATRI","N",15,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("VERBA MENSAL"   ,"VERBA MENSAL"   ,"T1_VERBA"  ,"N",15,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("PERCENTUAL"     ,"PERCENTUAL"     ,"T1_PERCEN" ,"N",10,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)

Return oStruct


Static Function ViewDef()
	Local oModel  := ModelDef()
	local oStrCab as object
	Local oFilho := FWFormViewStruct():New()
	Local oView
	Local oCalc1

	// Estrutura Fake de Field
	oStrCab := FWFormViewStruct():New()
	oStrCab:addField("C_STRING1", "01" , "String 01", "Campo de texto", , "C" )

	oFilho:AddField("T1_DIVISAO" ,"01","DIVISAO"        ,"DIVISAO"        ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:AddField("T1_METAMES" ,"02","META MENSAL"    ,"META MENSAL"    ,Nil,"N","@E 99,999,999,999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:AddField("T1_METATRI" ,"03","META TRIMESTRAL","META TRIMESTRAL",Nil,"N","@E 99,999,999,999.99",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:AddField("T1_VERBA"   ,"04","VERBA MENSAL"   ,"VERBA MENSAL"   ,Nil,"N","@E 99,999,999,999.99",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:AddField("T1_PERCEN"  ,"05","PERCENTUAL %"   ,"PERCENTUAL %"   ,Nil,"N","@E 999.9",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:AddField("T1_NDIVI"   ,"06","NDIVISAO"       ,"NDIVISAO"       ,Nil,"C","@E 9999",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oFilho:RemoveField("T1_NDIVI")

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("FFIL",oStrCAB,"MSTCAB")
	oView:AddGrid("FDET",oFilho,"DETSZ3")
	oCalc1 := FWCalcStruct( oModel:GetModel( 'COMP022CALC1') )
	oView:AddField( 'VIEW_CALC', oCalc1, 'COMP022CALC1' )

	// --- Definição da Tela
	oView:CreateHorizontalBox("BXFIL",0)
	oView:CreateHorizontalBox("BXREG",80)
	oView:CreateHorizontalBox("RODAPE",20)
	oView:CreateVerticalBox("BOX_INFERIOR_ESQUERDO",12, "RODAPE")
	oView:CreateVerticalBox("BOX_INFERIOR_DIREITO",88, "RODAPE")
	oView:AddUserButton("Alterar Trimestre","MAGIC_BMP",{|oView| loadGrid2()},"Alterar Trimestre", , , .T.)

	// --- Definição dos campos
	oView:SetOwnerView("FFIL","BXFIL")
	oView:SetOwnerView("FDET","BXREG")
	oView:SetOwnerView("VIEW_CALC","BOX_INFERIOR_DIREITO")

Return oView

//Só efetua a alteração do campo para inserção
static function onActivate(oModel)
	if oModel:GetOperation() == MODEL_OPERATION_INSERT
	    FwFldPut("C_STRING1", "FAKE" , /*nLinha*/, oModel)
	endif
return

//Carrega o Grid
static function loadGrid(oModel)
	Local aRet   := {}
	DbSelectArea("TCAB")
	TCAB->(DbGoTop())
	aRet := FwLoadByAlias(oModel, "TCAB")
return aRet

static function loadGrid2()
	Local oModel  := FWModelActive()
	Local oGrid   := oModel:GetModel("DETSZ3")
	Local oTotal  := oModel:GetModel("COMP022CALC1")
	Local cMsg 	  := ""
	Local nX := nMes:= nTri:= nVer := nDados:=0

	Do Case
		Case Month(Date()) >= 1 .And. Month(Date()) <= 3
			aMes := {"1","2","3"}
		Case Month(Date()) > 3 .And. Month(Date()) <= 6
			aMes := {"4","5","6"}
		Case Month(Date()) > 6 .And. Month(Date()) <= 9
			aMes := {"7","8","9"}
		Case Month(Date()) > 9 .And. Month(Date()) <= 12
			aMes := {"A","B","C"}
	EndCase

	For nX := 1 To Len(aNDivisao)
		If SX5->(DbSeek(xFilial("SX5")+"X4"+aNDivisao[nX]+cValToChar(Year(Date()))+aMes[1]))
			oGrid:GoLine(nX)
			oGrid:LoadValue("T1_DIVISAO" , aDivisao[nX])
			oGrid:LoadValue("T1_METAMES" , Val(SX5->X5_DESCRI))
			oGrid:LoadValue("T1_METATRI" , (Val(SX5->X5_DESCRI))*3)
			oGrid:LoadValue("T1_VERBA"   , Val(SX5->X5_DESCSPA))
			oGrid:LoadValue("T1_PERCEN"  , Val(SX5->X5_DESCSPA)/(Val(SX5->X5_DESCRI)/100))
			oGrid:LoadValue("T1_NDIVI"   , aNDivisao[nX])
			nMes += Val(SX5->X5_DESCRI)
			nTri += ((Val(SX5->X5_DESCRI))*3)
			nVer += Val(SX5->X5_DESCSPA)
			nDados++
		End 
	Next

	If nDados == 0 
		cMsg := '<font color="#0F0F00" size="5">Não foram encontrados valores referentes ao trimestre atual!</font>'
		FWAlertWarning(cMsg,'')
		Return
	EndIf

	oTotal:LoadValue("ZA2__TOT01" , nMes)
	oTotal:LoadValue("ZA2__TOT02" , nTri)
	oTotal:LoadValue("ZA2__TOT03" , nVer)
	oTotal:LoadValue("ZA2__TOT04" , nVer/(nMes/100))

	oGrid:GoLine(1)
	lAlt := .T.

return

//para inibir a pergunta se deseja salvar ou não ao clicar em cancelar.
Static Function Close(oModel)
	Local oView := FWViewActive()
	oView:SetModified(.F.)
Return .T.


Static Function CalcPer(oModel,nTotalAtual,xValor,lSomando)
	Local oCalc := oModel:GetModel("COMP022CALC1")
	Local nPerc := 0

	nPerc := oCalc:GetValue('ZA2__TOT03')/(oCalc:GetValue('ZA2__TOT01')/100)

Return nPerc

/*/{Protheus.doc} TCadMeV
Executa a lógica para gravação via reclock na X4 - SX5.
@type function
@author Rivaldo Jr.
@since 16/02/2023
/*/
Static Function Grava(oModel)
	Local oGrid    := oModel:GetModel("DETSZ3")
	Local nX 	   := nS:= 0
	Local nCount   := 0
	Local aMes 	   := {}
	Local aDados   := {}
	Local cMsg     := ""
	Local lOk 	   := .F.

	If !ogrid:IsUpdated()//Verifica se teve alteração na tela, para não salvar dados em branco.
		cMsg := '<font color="#0F0F00" size="5">Nenhum registro foi inserido!</font>'
		FWAlertWarning(cMsg,'')
		Return .F.
	EndIf

	Do Case
		Case Month(Date()) >= 1 .And. Month(Date()) <= 3
			aMes := {"1","2","3"}
		Case Month(Date()) > 3 .And. Month(Date()) <= 6
			aMes := {"4","5","6"}
		Case Month(Date()) > 6 .And. Month(Date()) <= 9
			aMes := {"7","8","9"}
		Case Month(Date()) > 9 .And. Month(Date()) <= 12
			aMes := {"A","B","C"}
	EndCase

	DbSelectArea("SX5")
	For nX := 1 To oGrid:Length()
		oGrid:GoLine(nX)
		aAdd(aDados,{oGrid:GetValue('T1_NDIVI'),oGrid:GetValue('T1_DIVISAO'),oGrid:GetValue('T1_METAMES'),oGrid:GetValue('T1_VERBA')})
	Next
	aSort(aDados, , , {|x, y| x[1] < y[1]})//Organiza os dados para salvar corretamente.

	For nS:= 1 To 3//Executa a gravação dos dados na tabela X4 da SX5.
		For nX := 1 To Len(aDados)
			If SX5->(DbSeek(xFilial("SX5")+"X4"+aDados[nX,1]+cValToChar(Year(YearSub(Date(),1)))+aMes[nS]))
				nCount++
			EndIf 
			If !SX5->(DbSeek(xFilial("SX5")+"X4"+aDados[nX,1]+cValToChar(Year(Date()))+aMes[nS]))
				SX5->(RecLock("SX5",.T.))
					SX5->X5_FILIAL  := cFilAnt
					SX5->X5_TABELA  := "X4"
					SX5->X5_CHAVE   := aDados[nX,1]+cValToChar(Year(Date()))+aMes[nS]
					SX5->X5_DESCRI  := cValToChar(aDados[nX,3])
					SX5->X5_DESCSPA := cValToChar(aDados[nX,4])
					SX5->X5_DESCENG := "0"
				SX5->(MsUnLock())
			Else 

				If lAlt
					cMsg := '<font color="#0F0F00" size="5">Já existem registros do trimestre atual,'+CRLF+'essa ação irá sobrescreve-los.'+CRLF+'Deseja Continuar ?</font>'
					lOk  := FWAlertYesNo(cMsg,"")
					lAlt := .F.
				End

				If lOk
					SX5->(RecLock("SX5",.F.))
						SX5->X5_FILIAL  := cFilAnt
						SX5->X5_TABELA  := "X4"
						SX5->X5_CHAVE   := aDados[nX,1]+cValToChar(Year(Date()))+aMes[nS]
						SX5->X5_DESCRI  := cValToChar(aDados[nX,3])
						SX5->X5_DESCSPA := cValToChar(aDados[nX,4])
						SX5->X5_DESCENG := "0"
					SX5->(MsUnLock())
				EndIf

			EndIf
		Next
	Next

	If nCount > 0
		cMsg := '<font color="#0F0F00" size="5">Existem registros do mesmo trimestre'+CRLF+'referente ao ano anterior'+CRLF+'deseja excluir ?</font>'
		If FWAlertYesNo(cMsg,"")
			For nS:= 1 To 3
				For nX := 1 To Len(aDados)
					If SX5->(DbSeek(xFilial("SX5")+"X4"+aDados[nX,1]+cValToChar(Year(YearSub(Date(),1)))+aMes[nS]))
						SX5->(RecLock("SX5",.F.))
							SX5->(DbDelete())
						SX5->(MsUnLock())
					EndIf
				Next
			Next
			FWAlertSuccess('<font color="#0F0F00" size="5">Registros excluidos com sucesso!</font>','')
		EndIf
	EndIf

Return .T.
