#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "protheus.ch"

/*/{Protheus.doc} ImpRom
Relatório de romaneio
@type function
@author Rivaldo Jr.
@since 11/06/2024
/*/
User Function ImpRom()
	Local lAdjustToLegacy:= .F.
	Local lDisableSetup  := .F. //Não abre tela de setup da impressão
	Local nFlags         := PD_ISTOTVSPRINTER+PD_DISABLEORIENTATION+PD_DISABLEPAPERSIZE+PD_DISABLEPREVIEW
	Local nLocal         := 2
	Local oSetup
	Local oPrint
	Local cChave	     := ""
    Local aPergs 		 := {}
	lOCAL nTotVol 		 := 0
	lOCAL nTotPeso		 := 0
	Local nPeso          := 0
	lOCAL nTotCub 		 := 0
	lOCAL nTotCar 		 := 0
	lOCAL nTotVlr 		 := 0
	lOCAL nVlr 		 	 := 0
	lOCAL nCub 	 		 := 0
	Local nVol			 := 0
	Local nCarg			 := 0
	Local nTotCarM3		 := 0
	Private nRecCount    := 0
	Private cAlias:= GetNextAlias()
	Private aArray := {}
	Private oFontTit:= TFont():New( "Arial", , -20, ,.T.)
	Private oFont0  := TFont():New( "Arial", , -7)
	Private oFont0n := TFont():New( "Arial", , -7,,.T.)
	Private oFont1  := TFont():New( "Arial", , -8)
	Private oFont3  := TFont():New( "Arial", , -10)
	Private oFont4  := TFont():New( "Arial", , -11)
	Private oFont1n := TFont():New( "Arial", , -8, ,.T.)
	Private oFont2  := TFont():New( "Arial", , -20, ,.T.)
	Private oFont4n := TFont():New( "Arial", , -15, ,.T.)
	Private oFont3n := TFont():New( "Arial", , -11, ,.T.)
	Private oFont2n := TFont():New( "Arial", , -9, ,.T.)
	Private oFont3ns:= TFont():New( "Arial", , -11, ,.T.,,,,,.T.)
	Private nLin       := 016
	Private nLinGrid   := 0
	Private nCol       := 0
	Private nLinBox    := 0
	Private nSpace5    := 5
	Private nSpace10   := 10
	Private nSpace15   := 15
	Private nSpace20   := 20
	Private nSpace30   := 30
	Private nSpace40   := 40
	Private nSpace50   := 50
	Private nSpace60   := 60
	Private oHGRAY     := TBrush():New( , CLR_HGRAY)
	Private oHLIGHTGRAY:= TBrush():New( , CLR_LIGHTGRAY)
	Private oHGREEN    := TBrush():New( , CLR_GREEN)
	Private oHCYAN     := TBrush():New( , CLR_HCYAN)
	Private oHBLACK    := TBrush():New( , RGB(000, 000, 000))
	Private oHWHITE    := TBrush():New( , RGB(255, 255, 255))
	Private oHRED      := TBrush():New( , RGB(255, 000, 000))

	aAdd(aPergs, {1, "Nº Carga"   ,space(TamSX3("DAK_COD")[1]),"@!",'.T.','DAK','.T.',TamSX3("DAK_COD")[1]+50	,.F.})//MV_PAR01

	If !parambox(aPergs,"Informe os parametros")
		Return
	EndIf

	oSetup:= FWPrintSetup():New(nFlags, "Cotação")
	oSetup:SetPropert(PD_PRINTTYPE   , 6)//ou 1
	oSetup:SetPropert(PD_ORIENTATION , 1)
	oSetup:SetPropert(PD_DESTINATION , nLocal)
	oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
	oSetup:SetPropert(PD_PAPERSIZE   , 2)

	If oSetup:Activate() == 1

 		cQuery := " SELECT D2_COD PROD, B1_PESO PESO, SUM(D2_QUANT) QUANT, DAK_CAPVOL TOTM3 "
 		cQuery += " FROM "+RETSQLNAME('DAK')+" DAK "
		cQuery += " INNER JOIN "+RETSQLNAME('DAI')+" DAI ON DAI_COD = DAK_COD AND DAI_SEQCAR = DAK_SEQCAR AND DAI_FILIAL = DAK_FILIAL AND DAI.D_E_L_E_T_ = '' " 
		cQuery += " INNER JOIN "+RETSQLNAME('SD2')+" SD2 ON SD2.D2_FILIAL = DAI.DAI_FILIAL AND SD2.D2_DOC = DAI_NFISCA AND SD2.D2_SERIE = DAI_SERIE AND SD2.D2_CLIENTE = DAI_CLIENT AND SD2.D2_LOJA = DAI_LOJA AND SD2.D_E_L_E_T_ = '' "
		cQuery += " INNER JOIN "+RETSQLNAME('SB1')+" SB1 ON SB1.B1_COD = SD2.D2_COD AND SB1.D_E_L_E_T_ = '' "
		cQuery += " LEFT JOIN "+RETSQLNAME('SF1')+" SF1 ON F1_DOC = DAI_NFISCA AND F1_SERIE = DAI_SERIE AND F1_FORNECE = DAI_CLIENT AND F1_LOJA = DAI_LOJA  AND  F1_FILIAL = DAI_FILIAL AND SF1.D_E_L_E_T_ = '' AND F1_TIPO = 'D' "
		cQuery += " WHERE DAK.DAK_COD = '"+MV_PAR01+"'  "
		cQuery += " AND SF1.F1_FILIAL IS NULL  "
		cQuery += " AND DAK.D_E_L_E_T_ = ''  "
		cQuery += " GROUP BY D2_COD, DAK_CAPVOL, B1_PESO " 
		cQuery += " ORDER BY D2_COD "
		MpSysOpenQuery(cQuery, "TMP")

		If TMP->(EOF())
			FwAlertWarning("Carga não localizada com os parâmetros fornecidos.","Atenção!")
			Return
		EndIf

		//Inicializacao da pagina do objeto grafico
		oPrint:= FWMSPrinter():New("Romaneio de Carregamento", IMP_PDF, lAdjustToLegacy,, lDisableSetup,,@oSetup)

		oPrint:StartPage()
		fCabec(oPrint)
		GridProd(oPrint)

		DbSelectArea("SB5")
		SB5->(DbSetOrder(1))
		DbSelectArea("SF2")
		SF2->(DbSetOrder(1))

		nTotCarM3 := TMP->TOTM3
                                                                                           
		While !TMP->(EOF())

			nCol:= 290

			If SB5->(DbSeek(xFilial("SB5")+TMP->PROD))
				nCub := ((SB5->B5_ALTURLC*SB5->B5_LARGLC*SB5->B5_COMPRLC)*TMP->QUANT)
			EndIf

			nVol  := TMP->QUANT
			nPeso := (TMP->PESO*TMP->QUANT)
			nCarg := ((nCub/nTotCarM3)*100)

			//Segundo
			oPrint:Box(nLin,0015, nLin+015, nCol+015, "-4")
			oPrint:Line(nLin,0100 ,nLin+15, 0100)//fim codigo

			oPrint:Say(nLin+010,0020, TMP->PROD ,oFont0)
			oPrint:Say(nLin+010,0105,Alltrim(Posicione('SB1', 1, FWxFilial('SB1') + TMP->PROD, 'B1_DESC')) ,oFont0)

			nCol+=20
			//Terceiro
			oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
			oPrint:Say(nLin+010,nCol+5,Padc(AllTrim(Transform(nVol,"@E 999,999")),25),oFont0)
			//oPrint:Say(nLin+010,nCol+5,'----------------------',oFont0)

			nCol+=70
			//Quarto
			oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
			oPrint:Say(nLin+010,nCol+5,Padl(AllTrim(Transform(nPeso,"@E 9999,999.99")),24) ,oFont0)

			nCol+=70
			//Quinto
			oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
			oPrint:Say(nLin+010,nCol+5,Padl(AllTrim(Transform(nCub,"@E 9999,999.99")),24) ,oFont0)

			nCol+=70
			//Sexto
			oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
			oPrint:Say(nLin+010,nCol+5,Padl(AllTrim(Transform(nCarg,"@E 9999,999.99"))+"%",22),oFont0)

			nTotVol += nVol
			nTotPeso+= nPeso
			nTotCub += nCub
			nTotCar += nCarg

			TMP->(dbSkip())

			nLin+=015

			If TMP->(EOF())
				nCol:= 290
				oPrint:Box(nLin,0015, nLin+015, nCol+15, "-6")
				oPrint:FillRect({nLin+1, 0016, nLin+014, nCol+14}, oHGRAY)
				oPrint:Say(nLin+010,0150, "TOTAL" ,oFont2n)

				nCol+=20
				//TOTAL VOLUME
				oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-6")
				oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)
				oPrint:Say(nLin+010,nCol+5,Padc(AllTrim(Transform(nTotVol,"@E 999,999")),23),oFont2n)

				nCol+=70
				//TOTAL PESO
				oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-6")
				oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)
				oPrint:Say(nLin+010,nCol+3,Padl(AllTrim(Transform(nTotPeso,"@E 999,999.99")),22) ,oFont2n)

				nCol+=70
				//TOTAL CUBAGEM
				oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-6")
				oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)
				oPrint:Say(nLin+010,nCol+5,Padl(AllTrim(Transform(nTotCub,"@E 999,999.99")),22) ,oFont2n)

				nCol+=70
				//TOTAL CARGA
				oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-6")
				oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)
				oPrint:Say(nLin+010,nCol+5,Padl(AllTrim(Transform(nTotCar,"@E 999,999.99"))+"%",20),oFont2n)
			EndIf

		End
		TMP->(DbCloseArea())

		GridNf(oPrint) // Imprimi o layout do acompanhamento e grid das NFs

		nTotVol := 0
		nTotPeso:= 0
		nTotCub := 0
		nTotCar := 0

		cQuery := " SELECT DAI_NFISCA NOTA, DAI_SERIE SERIE, DAI_CLIENT CLIENTE, DAI_LOJA LOJA, DAI_PESO PESO "
		cQuery += " FROM "+RETSQLNAME('DAK')+" DAK "
		cQuery += " INNER JOIN "+RETSQLNAME('DAI')+" DAI ON DAI_COD = DAK_COD AND DAI_SEQCAR = DAK_SEQCAR AND DAI_FILIAL = DAK_FILIAL AND DAI.D_E_L_E_T_ = '' " 
		cQuery += " LEFT JOIN "+RETSQLNAME('SF1')+" SF1 ON F1_DOC = DAI_NFISCA AND F1_SERIE = DAI_SERIE AND F1_FORNECE = DAI_CLIENT AND F1_LOJA = DAI_LOJA  AND  F1_FILIAL = DAI_FILIAL AND SF1.D_E_L_E_T_ = '' AND F1_TIPO = 'D' "
		cQuery += " WHERE DAK.DAK_COD = '"+MV_PAR01+"' "
		cQuery += " AND DAK.D_E_L_E_T_ = ''  "
		cQuery += " AND SF1.F1_FILIAL IS NULL  "
		cQuery += " GROUP BY DAI_NFISCA, DAI_SERIE, DAI_CLIENT, DAI_LOJA, DAI_PESO "
		cQuery += " ORDER BY DAI_NFISCA "
		MpSysOpenQuery(cQuery, "TMP")

		SD2->(DbSetOrder(3))

		While TMP->(!Eof())

			cNota := AllTrim(TMP->NOTA) 
			nCub  := 0
			nVol  := 0

			SF2->(DbSeek(xFilial("SF2")+TMP->(NOTA+SERIE+CLIENTE+LOJA)))
			If SD2->(DbSeek(SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)))
				cChave := SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA)
				While SD2->(!Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == cChave
					If SB5->(DbSeek(xFilial("SB5")+SD2->D2_COD))
						nCub += ((SB5->B5_ALTURLC*SB5->B5_LARGLC*SB5->B5_COMPRLC)*SD2->D2_QUANT)
					EndIf
					nVol+= SD2->D2_QUANT
					SD2->(DbSkip())
				End
			EndIf

			nPeso:= TMP->PESO
			nVlr := SF2->F2_VALBRUT
			nCarg:= ((nCub/nTotCarM3)*100)
			
			nLin+=7
			oPrint:Say(nLin,0383,OemToAnsi(cNota)			,oFont0)
			oPrint:Say(nLin,0410,OemToAnsi(Padl(AllTrim(Transform(nVol,"@E 999,999")),10))     	   ,oFont0)
			oPrint:Say(nLin,0445,OemToAnsi(Padl(AllTrim(Transform(nPeso,"@E 9999,999.99")),8))     ,oFont0)
			oPrint:Say(nLin,0475,OemToAnsi(Padl(AllTrim(Transform(nCub,"@E 9999,999.99")),8))      ,oFont0)
			oPrint:Say(nLin,0507,OemToAnsi(Padl(AllTrim(Transform(nCarg,"@E 9999,999.99"))+"%",8)) ,oFont0)
			oPrint:Say(nLin,0535,OemToAnsi("R$"+Padl(AllTrim(Transform(nVlr,"@E 9999,999.99")),13)),oFont0)

			nTotVol  += nVol
			nTotPeso += nPeso
			nTotCub  += nCub
			nTotCar  += nCarg
			nTotVlr  += nVlr

			TMP->(DbSkip())
			
 			If TMP->(Eof())
				nLin+=7
				oPrint:Line(nLin,0380,nLin, 580)
				oPrint:FillRect({nLin+1, 381, nLin+10, 579}, oHCYAN)
				nLin+=7
				oPrint:Say(nLin,0381,OemToAnsi("Total Geral"),oFont0n)
				oPrint:Say(nLin,0410,OemToAnsi(Padl(AllTrim(Transform(nTotVol,"@E 999,999")),10)) ,oFont0n)
				oPrint:Say(nLin,0445,OemToAnsi(Padl(AllTrim(Transform(nTotPeso,"@E 9999,999.99")),8)) ,oFont0n)
				oPrint:Say(nLin,0475,OemToAnsi(Padl(AllTrim(Transform(nTotCub,"@E 9999,999.99")),8)) ,oFont0n)
				oPrint:Say(nLin,0507,OemToAnsi(Padl(AllTrim(Transform(nTotCar,"@E 9999,999.99"))+"%",8)),oFont0n)
				oPrint:Say(nLin,0535,OemToAnsi('R$'+Padl(AllTrim(Transform(nTotVlr,"@E 9999,999.99")),13)),oFont0n)
			EndIf  

		End
		TMP->(DbCloseArea())

 		nLin := nLinGrid
		IF nLin > 600
			oPrint:EndPage()
			oPrint:StartPage()
			nLin := 022
		EndIF 

		RodaPe(oPrint) // Imprimi o rodapé p/ observações e assinaturas

		oPrint:Preview()
	EndIf

Return

/*/{Protheus.doc} fCabec
Imprime cabeçalho
@type function
@author Rivaldo Jr.
@since 11/06/2024
/*/
Static Function fCabec(oPrint)

	Local cStartPath:= GetSrvProfString("StartPath","")
	Local cLogo     := ''
	Local cDate     := ''
	Local cNome     := ''
	Local cPlaca 	:= ''
	Local cCgc      := ''
	Local cVeiculo  := ''
	Local cRota		:= ''
	//Local nLinAux   := 0

	DbSelectArea("DAK")
	DAK->(DbSetOrder(1))
	If DAK->(DbSeek(xFilial("DAK")+MV_PAR01))

		//cDate := DAK->DAK_DATA

		DbSelectArea("DA3")
		DA3->(DbSetOrder(1))
		If DA3->(DbSeek(xFilial("DA3")+DAK->DAK_CAMINH))
			cPlaca  := AllTrim(DA3->DA3_PLACA)
			cVeiculo:= AllTrim(DA3->DA3_DESC)
		EndIf
		DbSelectArea("DA4")
		DA4->(DbSetOrder(1))
		If DA4->(DbSeek(xFilial("DA4")+DAK->DAK_MOTORI))
			cNome := AllTrim(DA4->DA4_NOME)
			cCgc  := AllTrim(DA4->DA4_CGC)
		EndIf
		DbSelectArea("DA8")
		DA8->(DbSetOrder(1))
		If DA8->(DbSeek(xFilial("DA8")+DAK->DAK_ROTEIR))
			cRota := AllTrim(DA8->DA8_DESC)
		EndIf

	EndIf

	//Carrega img
	If SubStr(cStartPath,Len(cStartPath),1) <> "\"
		cStartPath	+= "\"
	EndIf
	cLogo:= cStartPath+"LGMID"+cEmpAnt+cFilAnt+".PNG"

	//Logo da Empresa
	//oPrint:SayBitmap(nLin,0000,cLogo,080,035)
	oPrint:SayBitmap(0000,0000,cLogo,0080,nLin+30)

	oPrint:Box(nLin ,0080,nLin+30, 580, "-4")
	oPrint:Line(nLin,0080,nLin+30, 0080)//Fim da Logo
	oPrint:Line(nLin,0155,nLin+30, 0155)//Fim da Data
	oPrint:Line(nLin,0415,nLin+30, 0415)//Fim do Romaneio
	oPrint:Line(nLin,0480,nLin+30, 0480)//Fim do Num Romaneio

	nLin+=nSpace10
	cDate := SubStr(DtoC(Date()),1,2)+"/"+SubStr(MesExtenso(Month(Date())),1,3)+"/"+cValToChar(Year(Date()))

	oPrint:Say(nLin+10,0085,OemToAnsi(cDate),oFont4n,, CLR_HRED)
	oPrint:Say(nLin+12,0160,OemToAnsi('ROMANEIO DE CARREGAMENTO'),oFontTit)
	oPrint:FillRect({nLin-9, 0416, nLin+20, 0479}, oHBLACK)
	oPrint:Say(nLin+1,0426,OemToAnsi('NÚMERO DO'),oFont2n,,CLR_WHITE)
	oPrint:Say(nLin+11,0428,OemToAnsi('ROMANEIO'),oFont2n,,CLR_WHITE)
	oPrint:Say(nLin+10,0485,OemToAnsi(cValToChar(Year(Date()))+'/'+AllTrim(MV_PAR01)),oFont2,, CLR_HRED)
    
	nLin+=nSpace30
	oPrint:Box(nLin,0015, nLin+110, 580, "-4")
	oPrint:FillRect({nLin+1, 0016, nLin+14, 579}, oHBLACK)
	oPrint:Say(nLin+10,0250,OemToAnsi('DADOS DO MOTORISTA'),oFont3n,,CLR_WHITE)
	oPrint:Line(nLin+15,0015,nLin+15,580)

	oPrint:Say(nLin+40,0060,OemToAnsi('NOME:'),oFont3)
	oPrint:Box(nLin+30,0090, nLin+45, 300, "-4")//Box nome
	oPrint:Say(nLin+40,0095,OemToAnsi(AllTrim(cNome)),oFont3n)

	oPrint:Say(nLin+40,0310,OemToAnsi('VEÍCULO'),oFont3)
	oPrint:Box(nLin+30,350, nLin+45, 520, "-4")//Box veiculo
	oPrint:Say(nLin+40,355,OemToAnsi(AllTrim(cVeiculo)),oFont3n)

	oPrint:Say(nLin+70,0065,OemToAnsi('CPF'),oFont3)
	oPrint:Box(nLin+60,0090, nLin+75, 300, "-4")//Box cpf
	If Len(cCgc) > 11
		cCgc := Alltrim(Transform(cCgc, "@R 99.999.999/9999-99"))
	Else 
		cCgc := Alltrim(Transform(cCgc, "@R 999.999.999-99"))
	EndIf
	oPrint:Say(nLin+70,0095,OemToAnsi(cCgc),oFont3n)

	oPrint:Say(nLin+70,0315,OemToAnsi('PLACA'),oFont3)
	oPrint:Box(nLin+60,350, nLin+75, 520, "-4")//Box placa
	oPrint:Say(nLin+70,355,OemToAnsi(AllTrim(cPlaca)),oFont3n)

	oPrint:Say(nLin+95,0060,OemToAnsi('ROTA'),oFont3)
	oPrint:Box(nLin+85,0090, nLin+100, 520, "-4")//Box Destino
	oPrint:Say(nLin+95,0095,OemToAnsi(cRota),oFont3n)
	nLin+=110

	nLin+=nSpace10
	oPrint:Box(nLin,0015, nLin+15, 580, "-4")
	oPrint:FillRect({nLin+1, 0016, nLin+14, 579}, oHBLACK)
	oPrint:Say(nLin+10,0260,OemToAnsi('DADOS DA CARGA'),oFont3n,,CLR_WHITE)

Return

/*/{Protheus.doc} GridProd
Retorna o cabeçalho dos ítens do relatório
@type function
@author Rivaldo Jr.
@since 11/06/2024
/*/
Static Function GridProd(oPrint)

	nLin+=nSpace30
	nCol+=290
	//Segundo
	oPrint:Box(nLin,0015, nLin+015, nCol+15, "-4")
	oPrint:FillRect({nLin+1, 0016, nLin+014, nCol+14}, oHLIGHTGRAY)
	oPrint:Line(nLin,0100 ,nLin+15, 0100)//fim codigo

	nCol+=20
	//Terceiro
	oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
	oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)

	nCol+=70
	//Quarto
	oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
	oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)

	nCol+=70
	//Quarto
	oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
	oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)

	nCol+=70
	//Quarto
	oPrint:Box(nLin,nCol, nLin+015, nCol+60, "-4")
	oPrint:FillRect({nLin+1, nCol+1, nLin+014, nCol+59}, oHLIGHTGRAY)

	nLin+=nSpace10
	oPrint:Say(nLin,0045,OemToAnsi('CÓDIGO') 	,oFont2n)
	oPrint:Say(nLin,0180,OemToAnsi('PRODUTOS')  ,oFont2n)
	oPrint:Say(nLin,0325,OemToAnsi('VOLUME') 	,oFont2n)
	oPrint:Say(nLin,0400,OemToAnsi('PESO')      ,oFont2n)
	oPrint:Say(nLin,0460,OemToAnsi('CUBAGEM')   ,oFont2n)
	oPrint:Say(nLin,0535,OemToAnsi('% CARGA')   ,oFont2n)
	nLin+=05

Return

/*/{Protheus.doc} GridNf
Monta o grid das NFs
@type function
@author Rivaldo Jr.
@since 11/06/2024
/*/
Static Function GridNf(oPrint)
	Local nColH := 0
	Local nColV := 0

	nLin+=nSpace30
	nColV+=0060
	nColH+=0060

	oPrint:Box(nLin,0015, nLin+200, 375, "-4")
	nLinGrid := nLin+220
	oPrint:FillRect({nLin+1, 0016, nLin+15, 374}, oHGREEN)
	oPrint:Say(nLin+12,0100,OemToAnsi('ACOMPANHAMENTO DO CARREGAMENTO'),oFont3n)
	oPrint:Line(nLin+15,0015 ,nLin+15, 375)

	oPrint:FillRect({nLin+16, 0016, nLin+44, 374}, oHLIGHTGRAY)
	oPrint:FillRect({nLin+76, 0016, nLin+104, 374}, oHLIGHTGRAY)
	oPrint:FillRect({nLin+136, 0016, nLin+164, 374}, oHLIGHTGRAY)
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 1º vertical
	oPrint:Line(nLin+30,nColH,nLin+30 , nColH+315)// 1º vertical
	oPrint:Say(nLin+35,0025,OemToAnsi('14X14'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 2º vertical
	oPrint:Line(nLin+45,0015,nLin+45 , nColH+315)// 1º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 3º vertical
	oPrint:Line(nLin+60,nColH,nLin+60 , nColH+315)// 1º vertical
	oPrint:Say(nLin+65,0025,OemToAnsi('21x23'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 4º vertical
	oPrint:Line(nLin+75,0015,nLin+75 , nColH+315)// 1º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 5º vertical
	oPrint:Line(nLin+90,nColH,nLin+90 , nColH+315)// 1º vertical
	oPrint:Say(nLin+95,0025,OemToAnsi('32x33'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 6º vertical
	oPrint:Line(nLin+105,0015,nLin+105 , nColH+315)// 1º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 7º vertical
	oPrint:Line(nLin+120,nColH,nLin+120 , nColH+315)// 1º vertical
	oPrint:Say(nLin+125,0030,OemToAnsi('102'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 8º vertical
	oPrint:Line(nLin+135,0015,nLin+135 , nColH+315)// 1º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 9º vertical
	oPrint:Line(nLin+150,nColH,nLin+150 , nColH+315)// 1º vertical
	oPrint:Say(nLin+155,0030,OemToAnsi('103'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 10º vertical
	oPrint:Line(nLin+165,0015,nLin+165 , nColH+315)// 1º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 11º vertical
	oPrint:Line(nLin+180,nColH,nLin+180 , nColH+315)// 1º vertical
	oPrint:Say(nLin+185,0025,OemToAnsi('Toalha'),oFont3n)
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 12º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 13º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 14º vertical
	nColV+=21
	oPrint:Line(nLin+15,nColV,nLin+200, nColV)// 15º vertical

	oPrint:Box(nLin,0380, nLin+200, 580, "-4")
	//oPrint:Box(nLin+5,0385, nLin+195, 575, "-4")
	oPrint:FillRect({nLin+1, 0381, nLin+15, 579}, oHCYAN)
	oPrint:Line(nLin+16,0380,nLin+16, 580)

	oPrint:Say(nLin+10,0385,OemToAnsi('Nº NF') 	   ,oFont0)
	oPrint:Say(nLin+10,0410,OemToAnsi('VOLUMES')   ,oFont0)
	oPrint:Say(nLin+10,0450,OemToAnsi('PESO') 	   ,oFont0)
	oPrint:Say(nLin+10,0472,OemToAnsi('CUBAGEM')   ,oFont0)
	oPrint:Say(nLin+10,0507,OemToAnsi('%CARGA')    ,oFont0)
	oPrint:Say(nLin+10,0545,OemToAnsi('VALOR')     ,oFont0)
	nLin+=20

Return

/*/{Protheus.doc} RodaPe
Monta o rodape da impressão.
@type function
@author Rivaldo Jr.
@since 11/06/2024
/*/
Static Function RodaPe(oPrint)
	Local nCol := 0

	nCol+=300

	oPrint:Box(nLin,0015, nLin+200, 580, "-4")
	oPrint:Say(nLin+10,0017,OemToAnsi('OBSERVAÇÕES:'),oFont3n,,CLR_HRED)
	oPrint:Line(nLin+090,0015,nLin+090,580)
	oPrint:Line(nLin+130,0115,nLin+130,480)
	oPrint:Say(nLin+140,00210,OemToAnsi('Assinatura do responsável pelo carregamento'),oFont3n,,CLR_BLACK)
	oPrint:Line(nLin+170,0115,nLin+170,480)
	oPrint:Say(nLin+180,0260,OemToAnsi('Assinatura do motorista'),oFont3n,,CLR_BLACK)
	oPrint:Say(nLin+197,0090,OemToAnsi('Declaro ter conferido o carregamento e verificado que as quantidades informadas estão corretas e que todo os produtos estão em perfeito estado.'),oFont0)
Return

