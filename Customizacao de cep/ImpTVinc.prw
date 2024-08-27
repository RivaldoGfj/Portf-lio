#INCLUDE "Protheus.Ch"
#INCLUDE 'TOTVS.CH'
#INCLUDE "SIGAWIN.CH"

/*/{Protheus.doc} ImpTVinc
Rotina de Importação de Arquivo .CSV para a tela de vinculo de Produtos.
@type function
@author Rivaldo Jr.
@since 11/11/2022
/*/
User Function ImpTVinc()

	Local cCaminho := ""
	Local cDirIni  := "C:/"
	Local aRes     := {}

	DEFINE MSDIALOG oDlg TITLE "Importação CSV" From 0,0 To 15,50

	oSayArq := tSay():New(15,07,{|| "Este programa tem como objetivo a importação de arquivos, onde os mesmos serão importados e diretamente alterados "+;
		"de um arquivo no formato CSV"+;
		"(Valores Separados por 'Ponto e Vírgula')."},oDlg,,,,,,.T.,,,200,80)

	oSayArq := tSay():New(45,07,{|| "Informe o local onde se encontra o arquivo para importação:"},oDlg,,,,,,.T.,,,200,80)
	oGetArq := TGet():New(55,05,{|u| If(PCount()>0,cCaminho:=u,cCaminho)},oDlg,150,10,'@!',,,,,,,.T.,,,,,,,,,,'cCaminho')

	oBtnArq := tButton():New(55,160,"Abrir...",oDlg,{|| cCaminho := cGetFile( "Arquivos CSV|*.csv|Arquivos CSV|*.csv", "Selecione o arquivo:",  1, cDirIni, .F., GETF_LOCALHARD, , .T. )},30,12,,,,.T.)
	oBtnImp := tButton():New(80,050,"Importar",oDlg,{|| aRes := ImpTvInc(cCaminho) },40,12,,,,.T.)
	oBtnCan := tButton():New(80,110,"Cancelar",oDlg,{|| oDlg:End()},40,12,,,,.T.)

	ACTIVATE MSDIALOG oDlg CENTERED

Return aRes

/*/{Protheus.doc} ImpTvInc
Localiza o arquivo CSV.
@type function
@author Rivaldo Jr.
@since 11/11/2022
@param cCaminho, character, String com o caminho do arquivo.
@return variant, Contem o retorno do processamento.
/*/
Static Function ImpTvInc(cCaminho)

	Local oProcess  := nil
	Local aRes      := nil
	Default cIdPlan := "1"
	Default cArq    := ""
	Default cDelimiter := "|"

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

/*/{Protheus.doc} ProcessCSV
Lê e carrega o arquivo CSV.
@type function
@author Rivaldo Jr.
@since 11/11/2022
@param cCaminho, character, String com o caminho do arquivo.
@param oProcess, object, Objeto do processo.
@return variant, Contem o retorno do processamento.
/*/
Static Function ProcessCSV(cCaminho,oProcess)
	Local nX
	Local cMsgHead  	:= "ICsvNat()"
	Local aRes     		:= {}
	Local aLines  		:= {}
	Local aLinha    	:= {}
	Local oFile     	As Object
	Local lManterVazio 	:= .T.
	Local lEnd         	:= .F.
	Private lMsErroAuto := .F.
	Private oTable		As Object

	oFile := FWFileReader():New(cCaminho)
	If oFile:Open() = .F.
		ApMsgStop("Não foi possvel efetuar a leitura do arquivo." + cArq, cMsgHead)
		Return aRes
	EndIf
	aLines := oFile:GetAllLines()

	if lEnd == .T.   //VERIFICAR SE NO CLICOU NO BOTAO CANCELAR
		ApMsgStop("Processo cancelado pelo usuário." + cArq, cMsgHead)
		Return aRes
	EndIf

	oProcess:IncRegua1("3/4 Ler Arquivo CSV")
	oProcess:SetRegua2(Len(aLines))

	For nX:=2 to len(aLines)
		if lEnd = .T.    //VERIFICAR SE NO CLICOU NO BOTAO CANCELAR
			ApMsgStop("Processo cancelado pelo usuário." + cArq, cMsgHead)
			Return {}
		EndIf
		oProcess:IncRegua2("Atualizando registro " + CvalToChar(nX) + " de " + cValToCHar(Len(aLines)) )
		cLinha  := aLines[nX]
		If Empty(cLinha) = .F.
			cLinha := StrTran(StrTran(cLinha, '"', ''), ",", ".")
			aLinha := Separa(cLinha, cDelimiter, lManterVazio)
			If Len(aLinha) > 0
				update(aLinha)
			EndIf
		EndIf
	Next

	oFile:Close()

	oProcess:IncRegua1("4/4 Remove temporarios")
	oProcess:SetRegua2(1)
	oProcess:IncRegua2("")

	MsgInfo("Processo finalizado.")

Return aRes

/*/{Protheus.doc} Update
Executa a Inclusão na tabela ZRC via reclock.
@type function
@author Rivaldo Jr.
@since 11/11/2022
@param aLinha, array, Array contendo os dados da linha executada.
/*/
Static Function Update(aLinha)
	Local aDados := {'0','1','2','3','4','5','6','7','8','9','s/n','Clique e Retire Correios'}
	Local nX 	 := 0
	Local cEnd 	 := aLinha[3]

	For nX := 1 To Len(aDados)
		cEnd := StrTran(cEnd, aDados[nX])
	Next

	//CEP|tipo_logradouro|Logradouro|Complemento|local|bairro|cidade|cod_cidade|UF|estado|cod_estado
	DbSelectArea("ZRC")
	ZRC->(RecLock("ZRC",.T.))

		ZRC->ZRC_CEP     := Padr(aLinha[1],TamSx3("ZRC_CEP")[1])
		ZRC->ZRC_EST     := Padr(DecodeUTF8(aLinha[9],"cp1252"),TamSx3("ZRC_EST")[1])
		ZRC->ZRC_ESTADO  := Padr(DecodeUTF8(aLinha[10],"cp1252"),TamSx3("ZRC_ESTADO")[1])
		ZRC->ZRC_MUN     := Padr(DecodeUTF8(aLinha[7],"cp1252"),TamSx3("ZRC_MUN")[1])
		ZRC->ZRC_CODMUN  := Padr(DecodeUTF8(aLinha[8],"cp1252"),TamSx3("ZRC_CODMUN")[1])
		ZRC->ZRC_BAIRRO  := Padr(DecodeUTF8(aLinha[6],"cp1252"),TamSx3("ZRC_BAIRRO")[1])
		ZRC->ZRC_END     := Padr(DecodeUTF8(cEnd  	 ,"cp1252"),TamSx3("ZRC_END")[1])

	ZRC->(MsUnlock())

Return
