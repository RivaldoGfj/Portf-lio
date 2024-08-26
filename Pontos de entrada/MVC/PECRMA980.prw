#include 'protheus.ch'
#include 'parmtype.ch'
#include 'FWMVCDEF.CH'

/*
IDs dos Pontos de Entrada
-------------------------

MODELPRE 			Antes da altera��o de qualquer campo do modelo. (requer retorno l�gico)
MODELPOS 			Na valida��o total do modelo (requer retorno l�gico)

FORMPRE 			Antes da altera��o de qualquer campo do formul�rio. (requer retorno l�gico)
FORMPOS 			Na valida��o total do formul�rio (requer retorno l�gico)

FORMLINEPRE 		Antes da altera��o da linha do formul�rio GRID. (requer retorno l�gico)
FORMLINEPOS 		Na valida��o total da linha do formul�rio GRID. (requer retorno l�gico)

MODELCOMMITTTS 		Apos a grava��o total do modelo e dentro da transa��o
MODELCOMMITNTTS 	Apos a grava��o total do modelo e fora da transa��o

FORMCOMMITTTSPRE 	Antes da grava��o da tabela do formul�rio
FORMCOMMITTTSPOS 	Apos a grava��o da tabela do formul�rio

FORMCANCEL 			No cancelamento do bot�o.

BUTTONBAR 			Para acrescentar botoes a ControlBar

MODELVLDACTIVE 		Para validar se deve ou nao ativar o Model

Parametros passados para os pontos de entrada:
PARAMIXB[1] - Objeto do formul�rio ou model, conforme o caso.
PARAMIXB[2] - Id do local de execu��o do ponto de entrada
PARAMIXB[3] - Id do formul�rio

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

	//'Chamada na valida��o total do modelo (MODELPOS).' 
	If  cIdPonto ==  'MODELPOS'
	// Antes da altera��o de qualquer campo do modelo.
	ElseIf cIdPonto ==  'MODELPRE'
	// Antes da altera��o de qualquer campo do formul�rio.
	ElseIf cIdPonto ==  'FORMPRE'
	//Chamada na valida��o total do formul�rio (FORMPOS)
	ElseIf cIdPonto ==  'FORMPOS'
	//Chamada na pre valida��o da linha do formul�rio (FORMLINEPRE)
	ElseIf cIdPonto ==  'FORMLINEPRE'
	//Chamada na valida��o da linha do formul�rio (FORMLINEPOS)
	ElseIf cIdPonto ==  'FORMLINEPOS'
	ElseIf cIdPonto ==  'MODELCOMMITTTS'
	//Chamada apos a grava��o total do modelo e fora da transa��o (MODELCOMMITNTTS)

		If lRet 
			GravaCV0(nOpc)// Fun��o para gravar e atualizar 
		EndIf

	ElseIf cIdPonto ==  'MODELCOMMITNTTS'
	//Chamada apos a grava��o da tabela do formul�rio (FORMCOMMITTTSPOS)
	ElseIf cIdPonto ==  'FORMCOMMITTTSPOS'
	// Chamada no Bot�o Cancelar (MODELCANCEL).
	ElseIf cIdPonto ==  'MODELCANCEL'
	// Adicionando Botao na Barra de Botoes (BUTTONBAR)
	ElseIf cIdPonto ==  'BUTTONBAR'
	// Chamada na valida��o da ativa��o do Model.
	ElseIf cIdPonto ==  'MODELVLDACTIVE'
	// Este ponto nao � nativo do MVC � preciso cria-lo no MENUDEF da aplicacao
	ElseIf cIdPonto ==  'MENUDEF'
	EndIf

Return lRet

/*/{Protheus.doc} GravaCV0
Fun��o para gravar e atualizar a entidade cont�bil
@type function
@author Rivaldo Jr.
@since 01/11/2023
@param nOpc, numeric, Opcao selecionada pelo usu�rio.
/*/
Static Function GravaCV0(nOpc)

	DbSelectArea("CV0")
	CV0->(DbSetOrder(1))
	
	If nOpc == 3 // Inclus�o

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

	ElseIf nOpc == 4 // Altera��o

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

	ElseIf nOpc == 5 // Exclus�o

		If CV0->(DbSeek(xFilial("CV0")+"05"+"C"+SA1->(A1_COD+A1_LOJA)))
			CV0->(RecLock("CV0", .F.))
				CV0->(DbDelete())
			CV0->(MsUnlock())
		EndIf

	EndIf

Return
