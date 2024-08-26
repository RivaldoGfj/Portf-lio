#include 'protheus.ch'
#include 'parmtype.ch'
#include 'FWMVCDEF.CH'

/*
IDs dos Pontos de Entrada
-------------------------

MODELPRE 			Antes da alteração de qualquer campo do modelo. (requer retorno lógico)
MODELPOS 			Na validação total do modelo (requer retorno lógico)

FORMPRE 			Antes da alteração de qualquer campo do formulário. (requer retorno lógico)
FORMPOS 			Na validação total do formulário (requer retorno lógico)

FORMLINEPRE 		Antes da alteração da linha do formulário GRID. (requer retorno lógico)
FORMLINEPOS 		Na validação total da linha do formulário GRID. (requer retorno lógico)

MODELCOMMITTTS 		Apos a gravação total do modelo e dentro da transação
MODELCOMMITNTTS 	Apos a gravação total do modelo e fora da transação

FORMCOMMITTTSPRE 	Antes da gravação da tabela do formulário
FORMCOMMITTTSPOS 	Apos a gravação da tabela do formulário

FORMCANCEL 			No cancelamento do botão.

BUTTONBAR 			Para acrescentar botoes a ControlBar

MODELVLDACTIVE 		Para validar se deve ou nao ativar o Model

Parametros passados para os pontos de entrada:
PARAMIXB[1] - Objeto do formulário ou model, conforme o caso.
PARAMIXB[2] - Id do local de execução do ponto de entrada
PARAMIXB[3] - Id do formulário

Se for uma FORMGRID
PARAMIXB[4] - Linha da Grid
PARAMIXB[5] - Acao da Grid

*/
/*/{Protheus.doc} CRMA980
Ponto de entrada da rotina EXEMPLO_MVC_PE (MVC)
@type function
@author Rivaldo Jr.
@since 01/11/2023
@return variant, logico
/*/
User Function CRMA980()
	Local aParam    := PARAMIXB
	Local oObj      := ''
	Local lRet		:= .T.
	Local cIdPonto  := ''
	Local cIdModel  := ''
	Local cClasse   := ''
	Local nLinha    := 0
	Local nQtdLinhas:= 0
	Local nOpc		:= 0

	oObj		:= aParam[1]
	cIdPonto	:= aParam[2]
	cIdModel	:= aParam[3]
	cClasse		:= oObj:ClassName()
	nOpc        := oObj:GetOperation()

	If cClasse == 'FWFORMGRID'
		nQtdLinhas := oObj:Length()
		nLinha     := oObj:nLine
	EndIf

	//'Chamada na validação total do modelo (MODELPOS).' 
	If  cIdPonto ==  'MODELPOS'
	// Antes da alteração de qualquer campo do modelo.
	ElseIf cIdPonto ==  'MODELPRE'
	// Antes da alteração de qualquer campo do formulário.
	ElseIf cIdPonto ==  'FORMPRE'
	//Chamada na validação total do formulário (FORMPOS)
	ElseIf cIdPonto ==  'FORMPOS'
	//Chamada na pre validação da linha do formulário (FORMLINEPRE)
	ElseIf cIdPonto ==  'FORMLINEPRE'
	//Chamada na validação da linha do formulário (FORMLINEPOS)
	ElseIf cIdPonto ==  'FORMLINEPOS'
	ElseIf cIdPonto ==  'MODELCOMMITTTS'
	//Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS)

		If lRet 
			GravaCV0(nOpc)// Função para gravar e atualizar 
		EndIf

	ElseIf cIdPonto ==  'MODELCOMMITNTTS'
	//Chamada apos a gravação da tabela do formulário (FORMCOMMITTTSPOS)
	ElseIf cIdPonto ==  'FORMCOMMITTTSPOS'
	// Chamada no Botão Cancelar (MODELCANCEL).
	ElseIf cIdPonto ==  'MODELCANCEL'
	// Adicionando Botao na Barra de Botoes (BUTTONBAR)
	ElseIf cIdPonto ==  'BUTTONBAR'
	// Chamada na validação da ativação do Model.
	ElseIf cIdPonto ==  'MODELVLDACTIVE'
	// Este ponto nao é nativo do MVC é preciso cria-lo no MENUDEF da aplicacao
	ElseIf cIdPonto ==  'MENUDEF'
	EndIf

Return lRet

/*/{Protheus.doc} GravaCV0
Função para gravar e atualizar a entidade contábil
@type function
@author Rivaldo Jr.
@since 01/11/2023
@param nOpc, numeric, Opcao selecionada pelo usuário.
/*/
Static Function GravaCV0(nOpc)

	DbSelectArea("CV0")
	CV0->(DbSetOrder(1))
	
	If nOpc == 3 // Inclusão

		CV0->(RecLock("CV0", .T.))
			CV0->CV0_FILIAL  := xFilial("CV0")
			CV0->CV0_PLANO   := "05"
			CV0->CV0_ITEM    := GetSxeNum("CV0","CV0_ITEM")
			CV0->CV0_CODIGO  := "C"+SA1->(A1_COD+A1_LOJA)
			CV0->CV0_DESC    := AllTrim(SA1->A1_NOME)
			CV0->CV0_BLOQUE  := 'N'
			CV0->CV0_CLASSE  := '2'//Analitica
			CV0->CV0_NORMAL  := '1'//Devedora
			CV0->CV0_DTIEXI  := dDataBase
		CV0->(MsUnlock())

	ElseIf nOpc == 4 // Alteração

		If CV0->(DbSeek(xFilial("CV0")+"05"+"C"+SA1->(A1_COD+A1_LOJA)))
			CV0->(RecLock("CV0", .F.))
				CV0->CV0_FILIAL  := CV0->CV0_FILIAL
				CV0->CV0_PLANO   := CV0->CV0_PLANO
				CV0->CV0_ITEM    := CV0->CV0_ITEM
				CV0->CV0_CODIGO  := "C"+SA1->(A1_COD+A1_LOJA)
				CV0->CV0_DESC    := AllTrim(SA1->A1_NOME)
				CV0->CV0_BLOQUE  := CV0->CV0_BLOQUE
				CV0->CV0_CLASSE  := CV0->CV0_CLASSE
				CV0->CV0_NORMAL  := CV0->CV0_NORMAL
				CV0->CV0_DTIEXI  := CV0->CV0_DTIEXI
			CV0->(MsUnlock())
		EndIf

	ElseIf nOpc == 5 // Exclusão

		If CV0->(DbSeek(xFilial("CV0")+"05"+"C"+SA1->(A1_COD+A1_LOJA)))
			CV0->(RecLock("CV0", .F.))
				CV0->(DbDelete())
			CV0->(MsUnlock())
		EndIf

	EndIf

Return
