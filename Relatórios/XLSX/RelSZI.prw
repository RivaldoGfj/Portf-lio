#include "Totvs.CH"
#include "TBICONN.ch"

static oCellHorAlign := FwXlsxCellAlignment():Horizontal()
static oCellVertAlign := FwXlsxCellAlignment():Vertical()
/*/{Protheus.doc} RelSZI
Geração de relatório .Xlsx e envio de arquivo via e-mail.
@type function
@author Rivaldo Jr.
@since 28/06/2023
/*/
User Function RelSZI()
	Local aPergs		 := {}
	Private cEmpAux		 := ''
	Private cEmpresa     := ''
	Private _DaData
	Private _AteData
	Private cArquivoFinal:= ''
	Private cArquivo 	 := ''
	Private cStyle  	 := FwXlsxBorderStyle():Thin() //01 - Thin - linha contínua
	Private cFont 	     := FwPrinterFont():Arial()
	Private cCustomFormat:= "R$ #,##0.00;[Red]-R$ #,##0.00"
	Private cHorAliCent  := oCellHorAlign:Center()
	Private cHorAliLeft  := oCellHorAlign:left()
	Private cHorAliRight := oCellHorAlign:right()
	Private cVertAliCent := oCellVertAlign:Center()
	Private cPath        := '\spool\arquivosExcel\'
	
	aAdd(aPergs, {1, "Da Empresa"      	       ,space(TamSX3("A1_filial")[1]),PesqPict("SA1","A1_filial"),,'SM0',,TamSX3("A1_filial")[1], .F.}) //MV_PAR01
	aAdd(aPergs, {1, "Ate a Empresa"   	       ,space(TamSX3("A1_filial")[1]),PesqPict("SA1","A1_filial"),,'SM0',,TamSX3("A1_filial")[1], .T.}) //MV_PAR02
	aAdd(aPergs, {1, "Do Centro de Custo"      ,space(TamSX3("CTT_CUSTO")[1]),PesqPict("CTT","CTT_CUSTO"),,'CTT',,TamSX3("CTT_CUSTO")[1], .F.}) //MV_PAR03
	aAdd(aPergs, {1, "Ate o Centro de Custo"   ,space(TamSX3("CTT_CUSTO")[1]),PesqPict("CTT","CTT_CUSTO"),,'CTT',,TamSX3("CTT_CUSTO")[1], .T.}) //MV_PAR04
	aAdd(aPergs, {1, "Da data"   	  	       ,Date()   , "", ".T.", "", ".T.", 80 , .F.}) //MV_PAR05
	aAdd(aPergs, {1, "Até a data"  	  	       ,Date()   , "", ".T.", "", ".T.", 80 , .T.}) //MV_PAR06

	If !parambox(aPergs,"Informe os parametros")
		Return
	EndIf

	_DaData 	:= FirstDate(MonthSub(dDataBase,1))
	_AteData 	:= LastDate(MonthSub(dDataBase,1))

	Processa({|| cArquivo := GeraExcel() },"Aguarde um momento, Gerando relatório...")

	If Empty(cArquivo)
		FwAlertWarning("Não foram encontrados dados com os parâmetros especificados", "Atenção!")
		Return
	EndIf

	oExib := MsExcel():New()             //Abre uma nova conexão com Excel
	oExib:WorkBooks:Open(cArquivo)     //Abre uma planilha
	oExib:SetVisible(.T.)                 //Visualiza a planilha
	oExib:Destroy()

Return

/*/{Protheus.doc} GeraExcel
Busca os dados e monta o arquivo .Xlsx
@type function
@author Rivaldo Jr.
@since 28/06/2023
/*/
Static Function GeraExcel()
	local oPrtXlsx 	     := FwPrinterXlsx():New()
	local oFileW   	     As Object
	Local cQuery		 := ''
	Local nRow 	   	     := 1

	cQuery += " SELECT ZI_FILIAL AS FILIAL,ZI_CLIENTE CLIENTE,ZI_LOJA LOJA,A1_NOME NOME,ZI_DOCORIG NFISCAL,ZI_SERIE SERIE,ZI_PRODUTO PRODUTO,  "
	cQuery += " 		B1_DESC DESCRI, SUBSTRING(F2.F2_EMISSAO,7,2)+'/'+SUBSTRING(F2.F2_EMISSAO,5,2)+'/'+LEFT(F2.F2_EMISSAO,4) EMISSAO, "
	cQuery += " 		ZI_PRECO PRECO,ZI_QTDPEDI QUANTPED,ZI_QTDENTR QUANTENT,(ZI_QTDPEDI-ZI_QTDENTR) SALDO "
	cQuery += " FROM FECHAMENTO_"+Substr(DtoS(_DaData),1,6)+"_SZI"+cEmpAux+"0 ZI, SA1"+cEmpAux+"0 A1, SB1"+cEmpAux+"0 B1, SF2"+cEmpAux+"0 F2 "
	cQuery += " WHERE A1_COD=ZI_CLIENTE AND A1_LOJA=ZI_LOJA AND ZI.D_E_L_E_T_='' AND ZI_PRODUTO=B1_COD AND ZI_QTDPEDI <> ZI_QTDENTR "
	cQuery += " 		AND B1.D_E_L_E_T_=''  AND A1.D_E_L_E_T_='' AND F2.D_E_L_E_T_='' AND A1_COD=F2_CLIENTE AND A1_LOJA=F2_LOJA  "
	cQuery += " 		AND ZI_CLIENTE=F2_CLIENTE AND ZI_LOJA=F2_LOJA AND ZI_DOCORIG=F2_DOC AND ZI_SERIE=F2_SERIE AND ZI_FILIAL=F2_FILIAL "
	cQuery += " 		AND F2_EMISSAO BETWEEN '"+DtoS(_DaData)+"' AND '"+DtoS(_AteData)+"' "
	cQuery += " ORDER BY 1,F2_EMISSAO "
	MpSysOpenQuery(cQuery, "cRelSZI")

	If cRelSZI->(Eof())
		return ''
	EndIf

	Do Case
		Case AllTrim(SM0->M0_CODIGO) == "01"
			cImgDir := GetSRVProfString("RootPath","")+cPath+'LogoEmis.png'
			cCor 	:= "FF0000"
		Case AllTrim(SM0->M0_CODIGO) == "02"
			cImgDir := GetSRVProfString("RootPath","")+cPath+'LogoCativa.png'
			cCor 	:= '0AC729'
		Case AllTrim(SM0->M0_CODIGO) == "03"
			cImgDir := GetSRVProfString("RootPath","")+cPath+'LogoNutiva.png'
			cCor 	:= '31869B'
	EndCase

	cEmp 		    := AllTrim(SM0->M0_NOME)
	cArquivo 	    := cPath+"SZI-"+cEmp+".rel"
	oFileW   	    := FwFileWriter():New(cArquivo)

	oPrtXlsx:Activate(cArquivo, oFileW)
	oPrtXlsx:AddSheet(cEmp)
	//definição da largura das colunas
	oPrtXlsx:SetColumnsWidth(1 , 1 , 6.78 )// FILIAL
	oPrtXlsx:SetColumnsWidth(2 , 2 , 9.56 )// COD. CLIENTE
	oPrtXlsx:SetColumnsWidth(3 , 3 , 6    )// LOJA
	oPrtXlsx:SetColumnsWidth(4 , 4 , 54.78)// NOME
	oPrtXlsx:SetColumnsWidth(5 , 5 , 11.12)// NOTA FISCAL
	oPrtXlsx:SetColumnsWidth(6 , 6 , 6.78 )// SERIE
	oPrtXlsx:SetColumnsWidth(7 , 7 , 12.56)// PRODUTO
	oPrtXlsx:SetColumnsWidth(8 , 8 , 30.11)// DESCRIÇÃO
	oPrtXlsx:SetColumnsWidth(9 , 9 , 11.33)// EMISSAO
	oPrtXlsx:SetColumnsWidth(10, 10, 15.89)// PRECO
	oPrtXlsx:SetColumnsWidth(11, 13, 11.44)// QTD. PED.| QTD. ENT.| SALDO

	oPrtXlsx:SetFont(cFont, 12, .F., .T., .F.) // seta o texto em negrito
	oPrtXlsx:MergeCells(/*lin inicial*/nRow,/*col inicial*/1,/*lin final*/nRow+2,/*col final*/13)// merge das celulas iniciais para o cabeçalho do arquivo
	If AllTrim(SM0->M0_CODIGO) == "01"
		oPrtXlsx:AddImageFromAbsolutePath(1, 12, cImgDir, 168 , 51)// adiciono a imagem a planilha
	Else 
		oPrtXlsx:AddImageFromAbsolutePath(1, 12, cImgDir, 385 , 100)// adiciono a imagem a planilha
	EndIf
	oPrtXlsx:SetCellsFormat(cHorAliCent, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0, "000000", "FFFFFF", "" )
	oPrtXlsx:SetText(/*nRow*/1, /*nCol*/ 1, "FECHAMENTO TABELA SZI ULTIMOS 30 DIAS - "+AllTrim(SM0->M0_NOME)) // Texto em A1

	nRow := nRow+3
	oPrtXlsx:MergeCells(/*linha inicial*/nRow, /*coluna inicial*/1, /*linha final*/nRow, /*coluna final*/4)
	oPrtXlsx:SetCellsFormat(cHorAliLeft, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0, "000000", "FFFFFF", "" )
	oPrtXlsx:SetValue( nRow , /*nCol*/1 ,  "Periodo: "+DtoC(_DaData) +" a "+ DtoC(_AteData))	//-- 1
	oPrtXlsx:SetValue( nRow , /*nCol*/2 ,  "")	//-- 2
	oPrtXlsx:SetValue( nRow , /*nCol*/3 ,  "")	//-- 3
	oPrtXlsx:SetValue( nRow , /*nCol*/4 ,  "")	//-- 4
	oPrtXlsx:SetValue( nRow , /*nCol*/5 ,  "")	//-- 5
	oPrtXlsx:SetValue( nRow , /*nCol*/6 ,  "")	//-- 6
	oPrtXlsx:SetValue( nRow , /*nCol*/7 ,  "")	//-- 7
	oPrtXlsx:SetValue( nRow , /*nCol*/8 ,  "")	//-- 8
	oPrtXlsx:SetValue( nRow , /*nCol*/9 ,  "")	//-- 9
	oPrtXlsx:SetValue( nRow , /*nCol*/10,  "")	//-- 10
	oPrtXlsx:SetValue( nRow , /*nCol*/11,  "")	//-- 11
	oPrtXlsx:SetValue( nRow , /*nCol*/12,  "")	//-- 12
	oPrtXlsx:SetValue( nRow , /*nCol*/13,  "")	//-- 13

	nRow++
	oPrtXlsx:SetCellsFormat(cHorAliLeft, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0, "FFFFFF", cCor, "" )//cabeçalho das colunas fundo vermelho
	oPrtXlsx:SetBorder(/*lLeft*/.T., /*lTop*/.T., /*lRight*/.T., /*lBottom*/.T., cStyle, "000000")//borda
	oPrtXlsx:SetText( nRow , /*nCol*/1 , "FILIAL"	) //-- 1
	oPrtXlsx:SetText( nRow , /*nCol*/2 , "CLIENTE"	) //-- 2
	oPrtXlsx:SetText( nRow , /*nCol*/3 , "LOJA"		) //-- 3
	oPrtXlsx:SetText( nRow , /*nCol*/4 , "NOME"		) //-- 4
	oPrtXlsx:SetText( nRow , /*nCol*/5 , "NFISCAL"	) //-- 5
	oPrtXlsx:SetText( nRow , /*nCol*/6 , "SERIE"	) //-- 6
	oPrtXlsx:SetText( nRow , /*nCol*/7 , "PRODUTO"	) //-- 7
	oPrtXlsx:SetText( nRow , /*nCol*/8 , "DESCRI"	) //-- 8
	oPrtXlsx:SetText( nRow , /*nCol*/9 , "EMISSAO"	) //-- 9
	oPrtXlsx:SetText( nRow , /*nCol*/10, "PRECO"	) //-- 10
	oPrtXlsx:SetCellsFormat(cHorAliCent, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0, "FFFFFF", cCor, "" )//cabeçalho das colunas fundo vermelho
	oPrtXlsx:SetText( nRow , /*nCol*/11, "QTD. PED.") //-- 11
	oPrtXlsx:SetText( nRow , /*nCol*/12, "QTD. ENT.") //-- 12
	oPrtXlsx:SetText( nRow , /*nCol*/13, "SALDO"	) //-- 13
	oPrtXlsx:ResetCellsFormat()

	oPrtXlsx:SetFont(cFont, 12, .F., .F., .F.) // seta o texto sem negrito
	While cRelSZI->(!Eof())
		nRow++
		oPrtXlsx:SetCellsFormat(cHorAliCent, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/1 , cRelSZI->FILIAL		) //-- 1
		oPrtXlsx:SetValue( nRow , /*nCol*/2 , cRelSZI->CLIENTE		) //-- 2
		oPrtXlsx:SetValue( nRow , /*nCol*/3 , cRelSZI->LOJA	    	) //-- 3
		oPrtXlsx:SetCellsFormat(cHorAliLeft, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/4 , AllTrim(cRelSZI->NOME)) //-- 4
		oPrtXlsx:SetCellsFormat(cHorAliCent, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/5 , cRelSZI->NFISCAL  	) //-- 5
		oPrtXlsx:SetValue( nRow , /*nCol*/6 , cRelSZI->SERIE		) //-- 6
		oPrtXlsx:SetValue( nRow , /*nCol*/7 , AllTrim(cRelSZI->PRODUTO)) //-- 7
		oPrtXlsx:SetCellsFormat(cHorAliLeft, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/8 , AllTrim(cRelSZI->DESCRI)) //-- 8
		oPrtXlsx:SetCellsFormat(cHorAliCent, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/9 , cRelSZI->EMISSAO  	) //-- 9
		oPrtXlsx:SetCellsFormat(cHorAliRight, cVertAliCent, /*lWrapText*/.F.,/*nRotation*/0,"000000","FFFFFF", cCustomFormat)
		oPrtXlsx:SetValue( nRow , /*nCol*/10, cRelSZI->PRECO		) //-- 10
		oPrtXlsx:SetCellsFormat(cHorAliRight, cVertAliCent, /*lWrapText*/.F., /*nRotation*/0,"000000","FFFFFF", "" )//cabeçalho das colunas fundo vermelho
		oPrtXlsx:SetValue( nRow , /*nCol*/11, cRelSZI->QUANTPED 	) //-- 11
		oPrtXlsx:SetValue( nRow , /*nCol*/12, cRelSZI->QUANTENT 	) //-- 12
		oPrtXlsx:SetValue( nRow , /*nCol*/13, cRelSZI->SALDO		) //-- 13
        cRelSZI->(DbSkip())
	EndDo
	cRelSZI->(DbCloseArea())

	oPrtXlsx:toXlsx()
	cArquivoFinal := StrTran(cArquivo, ".rel", ".xlsx")
	FErase(cArquivo)

Return cArquivoFinal
