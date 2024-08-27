#Include 'PROTHEUS.CH'
#Include 'TOTVS.CH'

/*/{Protheus.doc} TECA740
Ponto de entrada MVC na TECA740 Att de orçamento (Customização para Importacao de RH).
@type function
@author Rivaldo Jr.
@since 09/08/2024
/*/
User Function TECA740()
	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]
        
        If cIdPonto == 'BUTTONBAR'
			xRet := { {'Importar Recursos', 'Importar Recursos', { || u_ImpRec() }, 'Chama Função para Importação de Recursos' },;
			 		  {'Importar Materiais', 'Importar Materiais', { || u_ImpMat() }, 'Chama Função para Importação de Materiais' }}
		Endif

	Endif

Return xRet
