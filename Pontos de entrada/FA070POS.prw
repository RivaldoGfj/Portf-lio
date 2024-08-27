#Include 'Protheus.ch'

/*/{Protheus.doc} FA070POS
Manipula variáveis antes da montagem da tela de baixas a receber
Neste caso: Fixa o motivo de baixa como "Credito CC"
@type function
@author Rivaldo Jr.
@since 29/01/2024
/*/
User Function FA070POS()
	Local aArea := GetArea()
	Local nPriN := At(' ',SA1->A1_NOME)
	Local nSegN := At(' ',SUBSTR(SA1->A1_NOME,nPriN+1))

	cMotBx := 'CREDITO CC' 
	cHist070 := SubStr(SA1->A1_NOME, 1, (nPriN+nSegN))

	RestArea(aArea)
Return
