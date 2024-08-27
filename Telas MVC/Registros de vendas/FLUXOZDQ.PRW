#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "RWMAKE.CH"

#DEFINE  CABECALHO  "ZDQ_FILIAL/ZDQ_DOC/ZDQ_SERIE/ZDQ_CLIENTE/ZDQ_LOJA/ZDQ_NUM/ZDQ_EMISSAO/"
#DEFINE  ITENS1		"ZDQ_TM/ZDQ_COD/ZDQ_UM/ZDQ_PRECO/ZDQ_LOCAL/ZDQ_QUANT/"
#DEFINE  ITENS2		"ZDQ_TM/ZDQ_COD/ZDQ_UM/ZDQ_PRECO/ZDQ_LOCAL/ZDQ_QUANT/ZDQ_DOC/ZDQ_PEDIDO/"
Static 	 cTitle :=  "Fluxo Registros venda futura ( ZDQ )"

/*/{Protheus.doc} FLUXOZDQ
Tela MVC para consulta dos dados da tabela ZDQ.
@type function
@author Rivaldo Jr.
@since 23/10/2023
/*/
User Function FLUXOZDQ()
	Local aArea       := GetArea()
	Local oBrowse     := NIL
	Local oTempSF2ZDQ := NIL
	Local aCampos     := {}
	Local cQuery      := GetNextAlias()
	Local aStruT1 	  := NIL
	Local aColumns 	  := {}
	Local aTitulos 	  := {}
	Local nUltCol  	  := 0
	Local nAtual  	  := 0
	Private cNPro 	  := ''
	Private cQuant 	  := 0

	BeginSql Alias cQuery
		SELECT ZDQ_NPRO, ZDQ_FILIAL, ZDQ_DOC, ZDQ_SERIE, ZDQ_FORCLI, ZDQ_LOJA, ZDQ_DATA, ZDQ_PEDIDO, SUM(ZDQ_QUANT) AS QUANT, SUM(ZDQ_QTDENT) AS QTDENT
		FROM %Table:ZDQ% ZDQ
		WHERE ZDQ_TM = 'VF'
			AND ZDQ_FILIAL = %xFilial:ZDQ%
			AND ZDQ.%NOTDEL%
		GROUP BY ZDQ_NPRO, ZDQ_FILIAL, ZDQ_DOC, ZDQ_SERIE, ZDQ_FORCLI, ZDQ_LOJA, ZDQ_DATA, ZDQ_PEDIDO
		ORDER BY ZDQ_FILIAL, ZDQ_NPRO, ZDQ_DOC, ZDQ_SERIE
	EndSql

 	//// -- Criação da tabela temporária
	aAdd(aCampos,{"T1_FILIAL"   ,"C",2,0})
	aAdd(aCampos,{"T1_NPRO"  	,"C",6,0})
	aAdd(aCampos,{"T1_DOC"  	,"C",9,0})
	aAdd(aCampos,{"T1_SERIE"	,"C",3,0})
	aAdd(aCampos,{"T1_CLIENTE"	,"C",6,0})
	aAdd(aCampos,{"T1_LOJA"  	,"C",2,0})
	aAdd(aCampos,{"T1_NUM"		,"C",6,0})
	aAdd(aCampos,{"T1_EMISSAO"  ,"D",8,0})
	aAdd(aCampos,{"T1_QUANT"    ,"N",9,2})
	aAdd(aCampos,{"T1_QTDENT"   ,"N",9,2})
	
	//// --- Criar tabela temporária
	oTempSF2ZDQ := FWTemporaryTable():New("SF2ZDQ")
	oTempSF2ZDQ:SetFields(aCampos)
	oTempSF2ZDQ:AddIndex("01", {"T1_FILIAL","T1_NPRO","T1_DOC","T1_SERIE"})
	oTempSF2ZDQ:Create()

	While (cQuery)->(!Eof())
		SF2ZDQ->(RecLock('SF2ZDQ', .T.))
			SF2ZDQ->T1_FILIAL	:= (cQuery)->ZDQ_FILIAL
			SF2ZDQ->T1_NPRO		:= (cQuery)->ZDQ_NPRO
			SF2ZDQ->T1_DOC		:= (cQuery)->ZDQ_DOC
			SF2ZDQ->T1_SERIE	:= (cQuery)->ZDQ_SERIE
			SF2ZDQ->T1_CLIENTE	:= (cQuery)->ZDQ_FORCLI
			SF2ZDQ->T1_LOJA		:= (cQuery)->ZDQ_LOJA
			SF2ZDQ->T1_NUM		:= (cQuery)->ZDQ_PEDIDO
			SF2ZDQ->T1_EMISSAO	:= StoD((cQuery)->ZDQ_DATA)
 			SF2ZDQ->T1_QUANT	:= (cQuery)->QUANT 
			SF2ZDQ->T1_QTDENT	:= (cQuery)->QTDENT
		SF2ZDQ->(MsUnlock())
		(cQuery)->(DbSkip())
	End

	aStruT1 := SF2ZDQ->(DbStruct())
	aTitulos := {'FILIAL','PROCESSO','DOCUMENTO','SERIE','CLIENTE','LOJA','PEDIDO','DATA DA VENDA', 'QTD. TOTAL','Q. ENTREGUE'}

	For nAtual := 1 To Len(aStruT1)
		//Se o campo estiver contido na string
		If Alltrim(aStruT1[nAtual][1]) $ "T1_FILIAL/T1_NPRO/T1_DOC/T1_SERIE/T1_CLIENTE/T1_LOJA/T1_NUM/T1_EMISSAO/T1_QUANT/T1_QTDENT/"
			
			aAdd(aColumns,FWBrwColumn():New())//Adiciona no array, a coluna
			nUltCol := Len(aColumns)
			
			//Define os atributos das colunas
			aColumns[nUltCol]:SetData( &("{||"+aStruT1[nAtual][1]+"}") )
			aColumns[nUltCol]:SetTitle(aTitulos[nUltCol]) 
			aColumns[nUltCol]:SetSize(aStruT1[nAtual][3]) 
			aColumns[nUltCol]:SetDecimal(aStruT1[nAtual][4])
		EndIf     
	Next nAtual

	oBrowse := FWMBrowse():New()
	oBrowse:SetDescription(cTitle)
	oBrowse:SetAlias('SF2ZDQ')
	//Legendas
	oBrowse:AddLegend( "(SF2ZDQ->T1_QUANT <> SF2ZDQ->T1_QTDENT)", "GREEN", "Qtd. Entregue incompleto" )
	oBrowse:AddLegend( "(SF2ZDQ->T1_QUANT == SF2ZDQ->T1_QTDENT)", "RED"  , "Qtd. Entregue totalmente" )
	oBrowse:SetColumns(aColumns)
	oBrowse:DisableDetails()
	oBrowse:Activate()

	(cQuery)->(DbCloseArea())
	oBrowse:Destroy()
	FreeObj(oBrowse)

	RestArea(aArea)

Return

Static Function MenuDef()
	Private aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 1 ACCESS 0
	//ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 3 ACCESS 0
	//ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 4 ACCESS 0
	//ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Legenda'    ACTION 'U_MVCLegZDQ'        	OPERATION 6 ACCESS 0
	//ADD OPTION aRotina TITLE 'Importar'   ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 6 ACCESS 0
	//ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.FLUXOZDQ' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()
	Local oModel   	:= Nil
	Local oStPai   	:= fn01MCAB()//FWFormStruct( 1, 'SF2ZDQ', { |cCampo|  AllTrim( cCampo ) + '/' $ CABECALHO } )
	Local oStFilho 	:= FWFormStruct( 1, 'ZDQ', { |cCampo|  AllTrim( cCampo ) + '/' $ ITENS1}  )
	Local oStNeto 	:= FWFormStruct( 1, 'ZDQ', { |cCampo|  AllTrim( cCampo ) + '/' $ ITENS2}  )

	oModel := MPFormModel():New("MFLUXOZDQ")
	oModel:AddFields('SC5CAB',/*cOwner*/,oStPai)
	oModel:AddGrid('ZDQGRID1','SC5CAB',oStFilho, , , , ,{|oStFilho|CarGrid1( oStFilho )})//, {|oModel|AN002( oModel ) } )
	oModel:AddGrid('ZDQGRID2','ZDQGRID1',oStNeto, , , , ,{|oStNeto|CarGrid2( oStNeto )})//, {|oModel|AN002( oModel ) } )
	oModel:SetPrimaryKey({'T1_FILIAL','ZDQ_FILIAL'})

	//Setando as descrições
	oModel:GetModel('SC5CAB'):SetDescription('Cabecalho')
	oModel:GetModel('ZDQGRID1'):SetDescription('Itens da VF')
	oModel:GetModel('ZDQGRID2'):SetDescription('Itens da SR')

Return oModel

Static Function fn01MCAB()
	Local oStruct := FWFormModelStruct():New()

	oStruct:AddTable("SF2ZDQ",{"T1_FILIAL","T1_NPRO","T1_DOC","T1_SERIE"},"FILIAL")
	oStruct:AddField("FILIAL"   	,"FILIAL"       ,"T1_FILIAL"  ,"C",2,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("PROCESSO" 	,"PROCESSO"     ,"T1_NPRO"    ,"C",6,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("DOCUMENTO"	,"DOCUMENTO"    ,"T1_DOC"     ,"C",9,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("SERIE"    	,"SERIE"        ,"T1_SERIE"   ,"C",3,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("CLIENTE"		,"CLIENTE"	    ,"T1_CLIENTE" ,"C",6,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("LOJA"   		,"LOJA"   	    ,"T1_LOJA"    ,"C",2,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("PEDIDO"   	,"PEDIDO"       ,"T1_NUM" 	  ,"C",6,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("DATA DA V.F." ,"DATA DA V.F." ,"T1_EMISSAO" ,"D",8,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("QTD. TOTAL"	,"QTD. TOTAL"	,"T1_QUANT"   ,"N",9,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)
	oStruct:AddField("QTD. ENTREG." ,"QTD. ENTREGUE","T1_QTDENT"  ,"N",9,2,Nil,Nil,{},.F.,,.F.,.F.,.F.)

Return oStruct

Static Function ViewDef()
	Local oView     := Nil
	Local oModel    := FWLoadModel('FLUXOZDQ')
	Local oStPai 	:= FWFormViewStruct():New()//FWFormStruct( 2, 'SF2ZDQ' ,{ |cCampo|  AllTrim( cCampo ) + '/' $ CABECALHO } )
	Local oStFilho 	:= FWFormStruct( 2, 'ZDQ' ,{ |cCampo|  AllTrim( cCampo ) + '/' $ ITENS1 } )
	Local oStNeto 	:= FWFormStruct( 2, 'ZDQ' ,{ |cCampo|  AllTrim( cCampo ) + '/' $ ITENS2 } )

	oStPai:AddField("T1_FILIAL" ,"01","FILIAL"   	 ,"FILIAL"       ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_NPRO"   ,"02","PROCESSO" 	 ,"PROCESSO"     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_DOC"    ,"03","DOCUMENTO"	 ,"DOCUMENTO"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_SERIE"  ,"04","SERIE"    	 ,"SERIE"        ,Nil,"C","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_CLIENTE","05","CLIENTE"	 	 ,"CLIENTE"	     ,Nil,"C","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_LOJA"   ,"06","LOJA"   	 	 ,"LOJA"   	     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_NUM" 	,"07","PEDIDO"   	 ,"PEDIDO"       ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_EMISSAO","08","DATA DA V.F." ,"DATA DA V.F." ,Nil,"D",    ,Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_QUANT"  ,"09","QTD. TOTAL"   ,"QTD. TOTAL"   ,Nil,"N", "@E 999999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:AddField("T1_QTDENT" ,"10","QTD. ENTREG." ,"QTD. ENTREG." ,Nil,"N", "@E 999999.99",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
	oStPai:RemoveField("T1_FILIAL")	

	//Criando a View
	oView := FWFormView():New()
	oView:SetModel(oModel)

	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_CAB',oStPai,'SC5CAB')
	oView:AddGrid('VIEW_GRID1',oStFilho,'ZDQGRID1')
	oView:AddGrid('VIEW_GRID2',oStNeto,'ZDQGRID2')

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',18)
	oView:CreateHorizontalBox('GRID1',41)
	oView:CreateHorizontalBox('GRID2',41)

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_CAB','CABEC')
	oView:SetOwnerView('VIEW_GRID1','GRID1')
	oView:SetOwnerView('VIEW_GRID2','GRID2')

	//Habilitando título
	oView:EnableTitleView('VIEW_CAB','Cabeçalho')
	oView:EnableTitleView('VIEW_GRID1','Itens da Venda Futura')
	oView:EnableTitleView('VIEW_GRID2','Itens das Simples Remessas')

Return oView

//função para exibição das legendas na tela
User Function MVCLegZDQ()
	Local aLegenda := {}

	//Monta as cores
	AADD(aLegenda,{"BR_VERDE"	,  "Qtd. Entregue incompleto"  })
	AADD(aLegenda,{"BR_VERMELHO",  "Qtd. Totalmente Entregue"  })

	BrwLegenda("Detalhes da Quantidade", "Quantidade", aLegenda)
Return

//Carrega o Grid 1
static function CarGrid1(oStFilho)
	Local cZDQVF := GetNextAlias()
	Local aRet   := {}

	BeginSql Alias cZDQVF
	SELECT ZDQ_TM, ZDQ_COD, ZDQ_UM, ZDQ_LOCAL, ZDQ_PEDIDO, ZDQ_DATA, ZDQ_QUANT, ZDQ_PRECO, ZDQ_NPRO
	FROM %Table:ZDQ% ZDQ
	WHERE ZDQ_FILIAL = %xFilial:ZDQ%	
		AND ZDQ_TM = 'VF' // SIMPLES REMESSA
		AND ZDQ_DOC = %Exp:SF2ZDQ->T1_DOC%
		AND ZDQ_SERIE = %Exp:SF2ZDQ->T1_SERIE%
		AND ZDQ_FORCLI = %Exp:SF2ZDQ->T1_CLIENTE%
		AND ZDQ_LOJA = %Exp:SF2ZDQ->T1_LOJA%
		AND ZDQ_PEDIDO = %Exp:SF2ZDQ->T1_NUM%
		AND ZDQ.%NOTDEL% 
	EndSql

	cNPro := (cZDQVF)->ZDQ_NPRO

	(cZDQVF)->(DbGoTop())
	aRet := FwLoadByAlias(oStFilho, cZDQVF)
	(cZDQVF)->(DbCloseArea())

return aRet

//Carrega o Grid 2
static function CarGrid2(oModel)
	Local cZDQSR := GetNextAlias()
	Local aRet   := {}

	BeginSql Alias cZDQSR
	SELECT ZDQ_TM, ZDQ_COD, ZDQ_UM, ZDQ_LOCAL, ZDQ_PEDIDO, ZDQ_DATA, ZDQ_QUANT, ZDQ_PRECO, ZDQ_DOC
	FROM %Table:ZDQ% ZDQ
	WHERE ZDQ_FILIAL = %xFilial:ZDQ%	
		AND ZDQ_TM = 'SR' // SIMPLES REMESSA
		AND ZDQ_NPRO = %EXP:cNPro%
		AND ZDQ.%NOTDEL% 
	EndSql

	(cZDQSR)->(DbGoTop())
	aRet := FwLoadByAlias(oModel, cZDQSR)
	(cZDQSR)->(DbCloseArea())

return aRet
