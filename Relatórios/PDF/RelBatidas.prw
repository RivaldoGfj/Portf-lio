#INCLUDE "PROTHEUS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} RelBat
Monta pdf contendo um grid com apontamento de batidas divergentes.
@type function
@author Rivaldo Jr.
@since 25/08/2024
/*/
User Function RelBat()
	Local lAdjustToLegacy := .F.
	Local lDisableSetup   := .T. //Não abre tela de setup da impressão
    Local cDestinatario   := SuperGetMV("MV_XEMAIL",.F.,"")
    Local cAssunto        := "Apontamentos com divergencias"
    Local cMsg            := ""
    Local cQuery          := ""
    Local cMat            := ""
    Local cNome           := ""
    Local cAp1            := ""
    Local cAp2            := ""
    Local cAp3            := ""
    Local cAp4            := ""
	Private oFont0        := TFont():New( "Arial", , -7)
	Private oFont1        := TFont():New( "Arial", , -8)
	Private oFont3        := TFont():New( "Arial", , -10)
	Private oFont4        := TFont():New( "Arial", , -11)
	Private oFont1n       := TFont():New( "Arial", , -8, ,.T.)
	Private oFont2        := TFont():New( "Arial", , -20, ,.T.)
	Private oFont3n       := TFont():New( "Arial", , -11, ,.T.)
	Private oFont2n       := TFont():New( "Arial", , -9, ,.T.)
	Private oFont3ns      := TFont():New( "Arial", , -11, ,.T.,,,,,.T.)
	Private nLin          := 022
	Private nLinBox       := 0
	Private nSpace5       := 5
	Private nSpace10      := 10
	Private nSpace15      := 15
	Private nSpace20      := 20
	Private nSpace30      := 30
	Private nSpace40      := 40
	Private nSpace50      := 50
	Private nSpace60      := 60
	Private oHGRAY        := TBrush():New( , CLR_HGRAY)

    cQuery := " SELECT P8_DATA , P8_MAT, P8_CC, P8_FILIAL, P8_FLAG, P8_HORA,P8_TPMARCA, RA_NOME "+CRLF
    cQuery += " FROM "+RetSqlName("SP8")+" SP8 "+CRLF
    cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA ON RA_FILIAL = P8_FILIAL AND RA_MAT = P8_MAT AND SRA.D_E_L_E_T_ = '' "+CRLF
    cQuery += " WHERE P8_FILIAL = '"+cFilAnt+"' "+CRLF
	cQuery += " AND P8_DATA = '"+DtoS(Date()-1)+"' "+CRLF
	cQuery += " AND P8_APONTA = 'S' "+CRLF
	cQuery += " AND P8_TPMCREP <> 'D' "+CRLF
	cQuery += " AND SP8.D_E_L_E_T_ = '' "+CRLF
	cQuery += " GROUP BY P8_FILIAL, P8_MAT, P8_CC, P8_DATA,P8_FLAG, P8_SEMANA, P8_HORA, P8_TPMARCA, RA_NOME "+CRLF
    MpSysOpenQuery(cQuery, "cQuery")

    If cQuery->(Eof())
        Return
    EndIf

	//Criando o objeto do FMSPrinter
	oPrint := FWMSPrinter():New("ImpApont", IMP_PDF, lAdjustToLegacy, , lDisableSetup)

    //Setando os atributos necessários do relatório
	oPrint:SetResolution(78)
	oPrint:SetPortrait()
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(60, 60, 60, 60)

	oPrint:nDevice  := IMP_PDF
	oPrint:cPathPDF := "\spool\"
	oPrint:lServer  := .T.
	oPrint:lViewPDF := .F.

    oPrint:StartPage()
    fCabec(oPrint)      //Imprime o cabeçalho do PDF
    fImpCbTit(oPrint)   //Imprime o cabeçalho das colunas do grid

    While cQuery->(!Eof())
        cMat := cQuery->P8_MAT
        cNome:= AllTrim(cQuery->RA_NOME)
        cAp1 := ""
        cAp2 := ""
        cAp3 := ""
        cAp4 := ""
        nBatidas := 0

        While cQuery->(!Eof()) .And. cMat == cQuery->P8_MAT
            Do Case 
                Case cQuery->P8_TPMARCA == '1E'
                    //cAp1 := cQuery->P8_TPMARCA
                    cAp1 := cValToChar(cQuery->P8_HORA)
                Case cQuery->P8_TPMARCA == '1S'
                    //cAp2 := cQuery->P8_TPMARCA
                    cAp2 := cValToChar(cQuery->P8_HORA)
                Case cQuery->P8_TPMARCA == '2E'
                    //cAp3 := cQuery->P8_TPMARCA
                    cAp3 := cValToChar(cQuery->P8_HORA)
                Case cQuery->P8_TPMARCA == '2S'
                    //cAp4 := cQuery->P8_TPMARCA
                    cAp4 := cValToChar(cQuery->P8_HORA)
            EndCase
            nBatidas++
            cQuery->(DbSkip())
        End

        If nBatidas == 4
            Loop
        EndIf

        IF nLin > 750
			oPrint:EndPage()
			oPrint:StartPage()
			nLin := 022
			fCabec(oPrint)
            fImpCbTit(oPrint)
		EndIF

        fImpItens(oPrint, cMat, cNome, cAp1, cAp2, cAp3, cAp4 ) //Imprime as linhas do grid 
        nLin+=nSpace5
    End

    oPrint:EndPage()

    //GPEMail(cAssunto, cMsg, cDestinatario, {"\spool\ImpApont.pdf"})//função padrão para envio de email
    //oPrint:Preview()
Return 


Static Function fCabec(oPrint)
	Local cStartPath:= GetSrvProfString("StartPath","")
    Local cLogo
    //Carrega vetor com dados da empresa
    Local aEmp      := fEmpFil()
    Local nLinAux   := 0
  
    //Carrega img
	If SubStr(cStartPath,Len(cStartPath),1) <> "\"
		cStartPath	+= "\"
	EndIf
	cLogo:= cStartPath+"lgrl01.bmp"
    //Logo da Empresa
    oPrint:SayBitmap(nLin,0040,cLogo,090,060)

    nLinAux := nLin
    //------------------------------- Dados da empresa --------------------------------//
    nLin +=nSpace15
    oPrint:Say(nLin,0225,OemToAnsi(AllTrim(aEmp[1])) 		,oFont3n) 
    nLin+=nSpace10
    oPrint:Say(nLin,0185,OemToAnsi( AllTrim(aEmp[2])+' - '+AllTrim(aEmp[3])+' - ' + AllTrim(aEmp[4])+' - '+AllTrim(aEmp[5])+' - CEP.: '+AllTrim(aEmp[6])  ) 		,oFont1)
    nLin+=nSpace10
    oPrint:Say(nLin,0235,OemToAnsi('CNPJ: '+AllTrim(aEmp[9]) +' - I.E.: '+AllTrim(aEmp[8]) )	,oFont1)
    nLin+=nSpace10

    nLin := nLinAux
    //------------------------------- Dados do Relatório --------------------------------//            
    nLin +=nSpace15+nSpace10
    oPrint:Say(nLin,0500,OemToAnsi('Data: '+DtoC(dDataBase)) 					,oFont0)	

    nLin+=nSpace50
    oPrint:Box(nLin,0015, nLin+15, 580, "-4")
    nLin+=nSpace10
    oPrint:Say(nLin,0210,OemToAnsi('BATIDAS DE PONTO COM DIVERGÊNCIA'),oFont3n)
    nLin+=nSpace30

Return            


Static Function fEmpFil()

    Local aRet := {}
    aADD(aRet, AllTrim(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_NOMECOM')))
    aADD(aRet, AllTrim(Capital(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_ENDENT'))))
    aADD(aRet, AllTrim(Capital(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_BAIRENT'))))
    aADD(aRet, AllTrim(Capital(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CIDENT'))))
    aADD(aRet, AllTrim(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_ESTENT')))
    aADD(aRet, TransForm(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CEPENT'),'@r 99999-999'))
    aADD(aRet, RetField('SM0',1,cEmpAnt+cFilAnt,'M0_TEL'))
    aADD(aRet, TransForm(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_INSC'),'@r 999.999.999.999'))
    aADD(aRet, TransForm(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CGC'),"@r 99.999.999/9999-99"))
    
Return(aRet)                                                                  


Static Function fImpCbTit(oPrint)

    nLin+=nSpace10
    oPrint:Box(nLin,0015, nLin+015, 580, "-4")
    oPrint:FillRect({nLin+1, 0016, nLin+014, 579}, oHGRAY) 
 
    oPrint:Line(nLin,0067 ,nLin+15, 0067)//fim matricula
    oPrint:Line(nLin,0345 ,nLin+15, 0345)//fim nome
    oPrint:Line(nLin,0405 ,nLin+15, 0405)//fim ap1
    oPrint:Line(nLin,0465 ,nLin+15, 0465)//fim ap2
    oPrint:Line(nLin,0525 ,nLin+15, 0525)//fim ap3

    nLin+=nSpace10
    oPrint:Say(nLin,0017,OemToAnsi('MATRICULA') ,oFont2n)
    oPrint:Say(nLin,0070,OemToAnsi('NOME') 	    ,oFont2n)
    oPrint:Say(nLin,0350,OemToAnsi('AP1')       ,oFont2n)
    oPrint:Say(nLin,0410,OemToAnsi('AP2') 		,oFont2n)
    oPrint:Say(nLin,0470,OemToAnsi('AP3') 		,oFont2n)
    oPrint:Say(nLin,0530,OemToAnsi('AP4')       ,oFont2n)
    nLin+=nSpace5
    
Return


Static Function fImpItens(oPrint, cMat, cDesc, cAp1, cAp2, cAp3, cAp4 )

    oPrint:Box(nLin,0015, nLin+015, 580, "-4")
 
    oPrint:Line(nLin,0067 ,nLin+15, 0067)//fim matricula
    oPrint:Line(nLin,0345 ,nLin+15, 0345)//fim nome
    oPrint:Line(nLin,0405 ,nLin+15, 0405)//fim ap1
    oPrint:Line(nLin,0465 ,nLin+15, 0465)//fim ap2
    oPrint:Line(nLin,0525 ,nLin+15, 0525)//fim ap3

    nLin+=nSpace10
    oPrint:Say(nLin,0017,AllTrim(cMat)          ,oFont2n)
    oPrint:Say(nLin,0070,AllTrim(cDesc) 	    ,oFont2n)
    oPrint:Say(nLin,0350,cAp1                   ,oFont2n)
    oPrint:Say(nLin,0410,cAp2            		,oFont2n)
    oPrint:Say(nLin,0470,cAp3            		,oFont2n)
    oPrint:Say(nLin,0530,cAp4                   ,oFont2n)
    
Return
