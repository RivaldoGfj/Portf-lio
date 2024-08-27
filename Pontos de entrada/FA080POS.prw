//Bibliotecas
#Include "Protheus.ch"

/*/{Protheus.doc} FA080POS
Manipula variáveis antes da montagem da tela de baixas a pagar
Neste caso: Fixa o motivo de baixa como "Debito CC"
@type function
@author Rivaldo Jr.
@since 29/01/2024
/*/
User Function FA080POS()
	Local aArea := GetArea()
	Local nPriN := At(' ',SA2->A2_NOME)
	Local nSegN := At(' ',SUBSTR(SA2->A2_NOME,nPriN+1))

	cMotBx := 'DEBITO CC'
	cHist070 := SubStr(SA2->A2_NOME, 1, (nPriN+nSegN))

	RestArea(aArea)
Return
