// -*- C++ -*-
//*****************************************************************************
// DESCRIPTION: SystemC bison parser
//
// This file is part of SystemC-Perl.
//
// Author: Wilson Snyder <wsnyder@wsnyder.org>
//
// Code available from: http://www.veripool.org/systemperl
//
//*****************************************************************************
//
// Copyright 2001-2009 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// Lesser General Public License or the Perl Artistic License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//****************************************************************************/

%{

#include <cstdio>
#include <fstream>
#include <stack>
#include <vector>
#include <map>
#include <deque>
#include <cassert>

#include "VParse.h"
#include "VParseGrammar.h"

#define YYERROR_VERBOSE 1
#define YYINITDEPTH 5000	// Large as the stack won't grow, since YYSTYPE_IS_TRIVIAL isn't defined
#define YYMAXDEPTH 5000

// See VParseGrammar.h for the C++ interface to this parser
// Include that instead of VParseBison.h

VParseGrammar*	VParseGrammar::s_grammarp = NULL;

//*************************************************************************

#define GRAMMARP VParseGrammar::staticGrammarp()
#define PARSEP VParseGrammar::staticParsep()

#define NEWSTRING(text) (string((text)))

#define VARRESET()	 { VARDECL(""); VARIO(""); VARSIGNED(""); VARRANGE(""); VARARRAY("");}
#define VARDECL(type)	 { GRAMMARP->m_varDecl = (type); }
#define VARIO(type)	 { GRAMMARP->m_varIO   = (type); }
#define VARSIGNED(value) { GRAMMARP->m_varSigned=(value); }
#define VARRANGE(range)	 { GRAMMARP->m_varRange=(range); }
#define VARARRAY(value)	 { GRAMMARP->m_varArray=(value); }
#define VARDONE(fl,name,value) {\
	if (GRAMMARP->m_varIO!="")   PARSEP->signalCb((fl),GRAMMARP->m_varIO,  (name),GRAMMARP->m_varRange, GRAMMARP->m_varArray, GRAMMARP->m_varSigned, "",      GRAMMARP->m_inFTask); \
	if (GRAMMARP->m_varDecl!="") PARSEP->signalCb((fl),GRAMMARP->m_varDecl,(name),GRAMMARP->m_varRange, GRAMMARP->m_varArray, GRAMMARP->m_varSigned, (value), GRAMMARP->m_inFTask); \
}

#define INSTPREP(cellmod,cellparam) { GRAMMARP->pinNum(1); GRAMMARP->m_cellMod=(cellmod); GRAMMARP->m_cellParam=(cellparam); }

static void PINDONE(VFileLine* fl, const string& name, const string& expr) {
    if (GRAMMARP->m_cellParam) {
	// Stack them until we create the instance itself
	GRAMMARP->m_pinStack.push_back(VParseGPin(fl, name, expr, GRAMMARP->pinNum()));
    } else {
	PARSEP->pinCb(fl, name, expr, GRAMMARP->pinNum());
    }
}

static void PINPARAMS() {
    // Throw out all the pins we found before we could do instanceCb
    while (!GRAMMARP->m_pinStack.empty()) {
	VParseGPin& pinr = GRAMMARP->m_pinStack.front();
	PARSEP->paramPinCb(pinr.m_fl, pinr.m_name, pinr.m_conn, pinr.m_number);
	GRAMMARP->m_pinStack.pop_front();
    }
}

/* Yacc */
int  VParseBisonlex(VParseBisonYYSType* yylvalp) { return PARSEP->lexToBison(yylvalp); }

void VParseBisonerror(const char *s) { VParseGrammar::bisonError(s); }

%}

%pure_parser
%token_table

// Generic types used by Verilog::Parser
// IEEE: real_number
%token<str>		yaFLOATNUM	"FLOATING-POINT NUMBER"

// IEEE: identifier, class_identifier, class_variable_identifier,
// covergroup_variable_identifier, dynamic_array_variable_identifier,
// enum_identifier, interface_identifier, interface_instance_identifier,
// package_identifier, type_identifier, variable_identifier,
%token<str>		yaID		"IDENTIFIER"

// IEEE: integral_number
%token<str>		yaINTNUM	"INTEGER NUMBER"
// IEEE: time_literal + time_unit
%token<str>		yaTIMENUM	"TIME NUMBER"
// IEEE: string_literal
%token<str>		yaSTRING	"STRING"
%token<str>		yaTIMINGSPEC	"TIMING SPEC ELEMENT"

%token<str>		ygenGATE	"GATE keyword"
%token<str>		ygenKEYWORD	"KEYWORD"
%token<str>		ygenNETTYPE	"NETTYPE keyword (tri0/wand/etc)"
%token<str>		ygenOPERATOR	"OPERATOR"
%token<str>		ygenSTRENGTH	"STRENGTH keyword (strong1/etc)"
%token<str>		ygenSYSCALL	"SYSCALL"

%token<str>		'!'
%token<str>		'#'
%token<str>		'%'
%token<str>		'&'
%token<str>		'('
%token<str>		')'
%token<str>		'*'
%token<str>		'+'
%token<str>		','
%token<str>		'-'
%token<str>		'.'
%token<str>		'/'
%token<str>		':'
%token<str>		';'
%token<str>		'<'
%token<str>		'='
%token<str>		'>'
%token<str>		'?'
%token<str>		'@'
%token<str>		'['
%token<str>		']'
%token<str>		'^'
%token<str>		'{'
%token<str>		'|'
%token<str>		'}'
%token<str>		'~'

// Specific keywords
// yKEYWORD means match "keyword"
// Other cases are yXX_KEYWORD where XX makes it unique,
// for example yP_ for punctuation based operators.
%token<str>		yALIAS		"alias"
%token<str>		yALWAYS		"always"
%token<str>		yAND		"and"
%token<str>		yASSERT		"assert"
%token<str>		yASSIGN		"assign"
%token<str>		yASSUME		"assume"
%token<str>		yAUTOMATIC	"automatic"
%token<str>		yBEFORE		"before"
%token<str>		yBEGIN		"begin"
%token<str>		yBIND		"bind"
%token<str>		yBINS		"bins"
%token<str>		yBINSOF		"binsof"
%token<str>		yBIT		"bit"
%token<str>		yBREAK		"break"
%token<str>		yBUF		"buf"
%token<str>		yBYTE		"byte"
%token<str>		yCASE		"case"
%token<str>		yCASEX		"casex"
%token<str>		yCASEZ		"casez"
%token<str>		yCHANDLE	"chandle"
%token<str>		yCLASS		"class"
%token<str>		yCLOCK		"clock"
%token<str>		yCLOCKING	"clocking"
%token<str>		yCONST		"const"
%token<str>		yCONSTRAINT	"constraint"
%token<str>		yCONTEXT	"context"
%token<str>		yCONTINUE	"continue"
%token<str>		yCOVER		"cover"
%token<str>		yCOVERGROUP	"covergroup"
%token<str>		yCOVERPOINT	"coverpoint"
%token<str>		yCROSS		"cross"
%token<str>		yDEASSIGN	"deassign"
%token<str>		yDEFAULT	"default"
%token<str>		yDEFPARAM	"defparam"
%token<str>		yDISABLE	"disable"
%token<str>		yDIST		"dist"
%token<str>		yDO		"do"
%token<str>		yELSE		"else"
%token<str>		yEND		"end"
%token<str>		yENDCASE	"endcase"
%token<str>		yENDCLASS	"endclass"
%token<str>		yENDCLOCKING	"endclocking"
%token<str>		yENDFUNCTION	"endfunction"
%token<str>		yENDGENERATE	"endgenerate"
%token<str>		yENDGROUP	"endgroup"
%token<str>		yENDINTERFACE	"endinterface"
%token<str>		yENDMODULE	"endmodule"
%token<str>		yENDPACKAGE	"endpackage"
%token<str>		yENDPROGRAM	"endprogram"
%token<str>		yENDPROPERTY	"endproperty"
%token<str>		yENDSEQUENCE	"endsequence"
%token<str>		yENDSPECIFY	"endspecify"
%token<str>		yENDTABLE	"endtable"
%token<str>		yENDTASK	"endtask"
%token<str>		yENUM		"enum"
%token<str>		yEVENT		"event"
%token<str>		yEXPECT		"expect"
%token<str>		yEXPORT		"export"
%token<str>		yEXTENDS	"extends"
%token<str>		yEXTERN		"extern"
%token<str>		yFINAL		"final"
%token<str>		yFIRST_MATCH	"first_match"
%token<str>		yFOR		"for"
%token<str>		yFORCE		"force"
%token<str>		yFOREACH	"foreach"
%token<str>		yFOREVER	"forever"
%token<str>		yFORK		"fork"
%token<str>		yFORKJOIN	"forkjoin"
%token<str>		yFUNCTION	"function"
%token<str>		yGENERATE	"generate"
%token<str>		yGENVAR		"genvar"
%token<str>		yIF		"if"
%token<str>		yIFF		"iff"
%token<str>		yIGNORE_BINS	"ignore_bins"
%token<str>		yILLEGAL_BINS	"illegal_bins"
%token<str>		yIMPORT		"import"
%token<str>		yINITIAL	"initial"
%token<str>		yINOUT		"inout"
%token<str>		yINPUT		"input"
%token<str>		yINSIDE		"inside"
%token<str>		yINT		"int"
%token<str>		yINTEGER	"integer"
%token<str>		yINTERFACE	"interface"
%token<str>		yINTERSECT	"intersect"
%token<str>		yJOIN		"join"
%token<str>		yLOCAL		"local"
%token<str>		yLOCALPARAM	"localparam"
%token<str>		yLOGIC		"logic"
%token<str>		yLONGINT	"longint"
%token<str>		yMATCHES	"matches"
%token<str>		yMODPORT	"modport"
%token<str>		yMODULE		"module"
%token<str>		yNAND		"nand"
%token<str>		yNEGEDGE	"negedge"
%token<str>		yNEW		"new"
%token<str>		yNOR		"nor"
%token<str>		yNOT		"not"
%token<str>		yNULL		"null"
%token<str>		yOR		"or"
%token<str>		yOUTPUT		"output"
%token<str>		yPACKAGE	"package"
%token<str>		yPACKED		"packed"
%token<str>		yPARAMETER	"parameter"
%token<str>		yPOSEDGE	"posedge"
%token<str>		yPRIORITY	"priority"
%token<str>		yPROGRAM	"program"
%token<str>		yPROPERTY	"property"
%token<str>		yPROTECTED	"protected"
%token<str>		yPURE		"pure"
%token<str>		yRAND		"rand"
%token<str>		yRANDC		"randc"
%token<str>		yRANDCASE	"randcase"
%token<str>		yRANDSEQUENCE	"randsequence"
%token<str>		yREAL		"real"
%token<str>		yREALTIME	"realtime"
%token<str>		yREF		"ref"
%token<str>		yREG		"reg"
%token<str>		yRELEASE	"release"
%token<str>		yREPEAT		"repeat"
%token<str>		yRETURN		"return"
%token<str>		ySCALARED	"scalared"
%token<str>		ySEQUENCE	"sequence"
%token<str>		ySHORTINT	"shortint"
%token<str>		ySHORTREAL	"shortreal"
%token<str>		ySIGNED		"signed"
%token<str>		ySOLVE		"solve"
%token<str>		ySPECIFY	"specify"
%token<str>		ySTATIC		"static"
%token<str>		ySTRING		"string"
%token<str>		ySTRUCT		"struct"
%token<str>		ySUPER		"super"
%token<str>		ySUPPLY0	"supply0"
%token<str>		ySUPPLY1	"supply1"
%token<str>		yTABLE		"table"
%token<str>		yTAGGED		"tagged"
%token<str>		yTASK		"task"
%token<str>		yTHIS		"this"
%token<str>		yTHROUGHOUT	"throughout"
%token<str>		yTIME		"time"
%token<str>		yTIMEPRECISION	"timeprecision"
%token<str>		yTIMEUNIT	"timeunit"
%token<str>		yTRI		"tri"
%token<str>		yTYPE		"type"
%token<str>		yTYPEDEF	"typedef"
%token<str>		yUNION		"union"
%token<str>		yUNIQUE		"unique"
%token<str>		yUNSIGNED	"unsigned"
%token<str>		yVAR		"var"
%token<str>		yVECTORED	"vectored"
%token<str>		yVIRTUAL	"virtual"
%token<str>		yVOID		"void"
%token<str>		yWAIT		"wait"
%token<str>		yWAIT_ORDER	"wait_order"
%token<str>		yWHILE		"while"
%token<str>		yWILDCARD	"wildcard"
%token<str>		yWIRE		"wire"
%token<str>		yWITH		"with"
%token<str>		yWITHIN		"within"
%token<str>		yXNOR		"xnor"
%token<str>		yXOR		"xor"

%token<str>		yP_OROR		"||"
%token<str>		yP_ANDAND	"&&"
%token<str>		yP_NOR		"~|"
%token<str>		yP_XNOR		"^~"
%token<str>		yP_NAND		"~&"
%token<str>		yP_EQUAL	"=="
%token<str>		yP_NOTEQUAL	"!="
%token<str>		yP_CASEEQUAL	"==="
%token<str>		yP_CASENOTEQUAL	"!=="
%token<str>		yP_WILDEQUAL	"==?"
%token<str>		yP_WILDNOTEQUAL	"!=?"
%token<str>		yP_GTE		">="
%token<str>		yP_LTE		"<="
%token<str>		yP_SLEFT	"<<"
%token<str>		yP_SRIGHT	">>"
%token<str>		yP_SSRIGHT	">>>"
%token<str>		yP_POW		"**"

%token<str>		yP_PARSTRENGTH	"(-for-strength"
%token<str>		yP_PLUSCOLON	"+:"
%token<str>		yP_MINUSCOLON	"-:"
%token<str>		yP_MINUSGT	"->"
%token<str>		yP_MINUSGTGT	"->>"
%token<str>		yP_EQGT		"=>"
%token<str>		yP_ASTGT	"*>"
%token<str>		yP_ANDANDAND	"&&&"
%token<str>		yP_POUNDPOUND	"##"
%token<str>		yP_DOTSTAR	".*"

%token<str>		yP_ATAT		"@@"
%token<str>		yP_COLONCOLON	"::"
%token<str>		yP_COLONEQ	":="
%token<str>		yP_COLONDIV	":/"
%token<str>		yP_ORMINUSGT	"|->"
%token<str>		yP_OREQGT	"|=>"

%token<str>		yP_PLUSPLUS	"++"
%token<str>		yP_MINUSMINUS	"--"
%token<str>		yP_PLUSEQ	"+="
%token<str>		yP_MINUSEQ	"-="
%token<str>		yP_TIMESEQ	"*="
%token<str>		yP_DIVEQ	"/="
%token<str>		yP_MODEQ	"%="
%token<str>		yP_ANDEQ	"&="
%token<str>		yP_OREQ		"|="
%token<str>		yP_XOREQ	"^="
%token<str>		yP_SLEFTEQ	"<<="
%token<str>		yP_SRIGHTEQ	">>="
%token<str>		yP_SSRIGHTEQ	">>>="

// [* is not a operator, as "[ * ]" is legal
// [= and [-> could be repitition operators, but to match [* we don't add them.
// '( is not a operator, as "' (" is legal
// '{ could be an operator.  More research needed.

//********************
// Verilog op precedence

%token<str>	prUNARYARITH
%token<str>	prREDUCTION
%token<str>	prNEGATION


%left		':'
%left		'?'
%left		yP_OROR
%left		yP_ANDAND
%left		'|' yP_NOR
%left		'^'
%left		yP_XNOR
%left		'&' yP_NAND
%left		yP_EQUAL yP_NOTEQUAL yP_CASEEQUAL yP_CASENOTEQUAL yP_WILDEQUAL yP_WILDNOTEQUAL
%left		'>' '<' yP_GTE yP_LTE
%left		yP_SLEFT yP_SRIGHT yP_SSRIGHT
%left		'+' '-'
%left		'*' '/' '%'
%left		yP_POW
%left		'{' '}'
%left		prUNARYARITH yP_MINUSMINUS yP_PLUSPLUS
%left		prREDUCTION
%left		prNEGATION

%nonassoc prLOWER_THAN_ELSE
%nonassoc yELSE

//BISONPRE_TYPES
//  Blank lines for type insertion
//  Blank lines for type insertion
//  Blank lines for type insertion

%start fileE

%%
//**********************************************************************
// Feedback to the Lexer
// Note we read a parenthesis ahead, so this may not change the lexer at the right point.

statePushVlg:	/* empty */			 	{ }
	;
statePop:	/* empty */			 	{ }
	;

//**********************************************************************
// Files

fileE:		/* empty */				{ }
	|       timeunits_declarationE 	file	      	{ }
	;

file:		description				{ }
	|	file description			{ }
	;

description:			// ==IEEE: description
//	|	udp_declaration				{ }
		module_declaration			{ }
	|	interfaceDecl				{ }
//	|	program_declaration			{ }
//	|	package_declaration			{ }
	|	package_item				{ }
//	|	bind_directive				{ }
	|	error					{ }
	;

timeunits_declarationE:		// IEEE: timeunits_declaration + empty
		/*empty*/							{ }
        |	yTIMEUNIT       yaTIMENUM ';'					{ }
	| 	yTIMEPRECISION  yaTIMENUM ';'					{ }
	| 	yTIMEUNIT       yaTIMENUM ';' yTIMEPRECISION  yaTIMENUM ';' 	{ }
	| 	yTIMEPRECISION  yaTIMENUM ';' yTIMEUNIT       yaTIMENUM ';'	{ }
	;

//**********************************************************************
// Packages

package_item:		// ==IEEE: package_item
		package_or_generate_item_declaration	{ }
//	|	anonymous_program			{ }
//	|	timeunits_declaration			{ }
 	;

package_or_generate_item_declaration:	// ==IEEE: package_or_generate_item_declaration
	//				// varDecl == net_declatation | data_declaration
		varDecl					{ }
//	|	task_declaration			{ }
//	|	function_declaration			{ }
//	|	dpi_import_export			{ }
//	|	extern_constraint_declaration		{ }
	|	class_declaration			{ }
//	|	class_constructor_declaration		{ }
//	|	parameter_declaration ';'		{ }
//	|	local_parameter_declaration		{ }
//	|	covergroup_declaration			{ }
//	|	overload_declaration			{ }
//	|	concurrent_assertion_item_declaration	{ }
	|	';'					{ }
	;

//**********************************************************************
// Module headers

module_declaration:		// ==IEEE: module_declaration (incomplete)
		modHeader  timeunits_declarationE modItemListE yENDMODULE endLabelE
			{ PARSEP->endmoduleCb($<fl>4,$4); }
	;
modHeader:	modHdr  parameter_port_listE modPortsE ';' { }
	;
modHdr:		yMODULE lifetimeE yaID		{ PARSEP->moduleCb($<fl>1,$1,$3,PARSEP->inCellDefine()); }
	;
parameter_port_listE:		// IEEE: parameter_port_list + empty (complete)
		/* empty */				{ }
	|	'#' '(' ')'				{ }
	|	'#' '(' modParArgs ')'			{ }
	;

modParArgs:	modParDecl				{ }
	|	modParDecl ',' modParList		{ }
	;

modParList:	modParSecond				{ }
	|	modParList ',' modParSecond 		{ }
	;

// Called only after a comma in a v2k list, to allow parsing "parameter a,b, parameter x"
modParSecond:	modParDecl				{ }
	|	param					{ }
	;

modPortsE:	/* empty */					{ }
	|	'(' ')'						{ }
	|	'(' {GRAMMARP->pinNum(1);} portList ')'		{ }
	|	'(' {GRAMMARP->pinNum(1);} portV2kArgs ')'	{ }
	;

modPortsStarE:	/* empty */					{ }
	|	'(' '*' ')'					{ }
	|	'(' ')'						{ }
	|	'(' {GRAMMARP->pinNum(1);} portList ')'		{ }
	|	'(' {GRAMMARP->pinNum(1);} portV2kArgs ')'	{ }
	;

portList:	port					{ }
	|	portList ',' port	  		{ }
	;

port:		yaID portRangeE				{ PARSEP->portCb($<fl>1, $1); }
	;

portV2kArgs:	portV2kDecl				{ }
	|	portV2kDecl ',' portV2kList		{ }
	;

portV2kList:	portV2kSecond				{ }
	|	portV2kList ',' portV2kSecond		{ }
	;

// Called only after a comma in a v2k list, to allow parsing "input a,b"
portV2kSecond:	portV2kDecl				{ }
	|	portV2kInit				{ }
	;

portV2kInit:	portV2kSig				{ }
	|	portV2kSig '=' expr			{ }
	;

portV2kSig:	sigAndAttr				{ $<fl>$=$<fl>1; PARSEP->portCb($<fl>1, $1); }
	;

//**********************************************************************
// Interface headers

// IEEE: interface_declaration + interface_nonansi_header + interface_ansi_header:
interfaceDecl:	intHdr parameter_port_listE modPortsStarE ';' timeunits_declarationE interfaceItemListE yENDINTERFACE endLabelE
			{ PARSEP->endinterfaceCb($<fl>7,$7); }
	|	yEXTERN	intHdr parameter_port_listE modPortsE ';'	{ }
	;

intHdr:		yINTERFACE lifetimeE yaID		{ PARSEP->interfaceCb($<fl>1,$1,$3); }
	;

interfaceItemListE:
		/* empty */				{ }
	|	interfaceItemList			{ }
	;

interfaceItemList:
		interfaceItem				{ }
	|	interfaceItemList interfaceItem		{ }
	;

// IEEE: interface_item + non_port_interface_item
interfaceItem:
		varDecl					{ }
	|	generate_region				{ }
	|	interface_or_generate_item		{ }
	|	interfaceDecl				{ }
	//|	program_declaration
	;

interface_or_generate_item:	// ==IEEE: interface_or_generate_item
		modport_declaration			{ }
	//|	moduleCommonItem			{ }
	//|	extern_tf_declaration			{ }
	;

modport_declaration:		// ==IEEE: modport_declaration
		yMODPORT modportItemList ';'		{ }
	;

modportItemList: modport_item				{ }
	|	modportItemList ',' modport_item	{ }
	;

modport_item:			// ==IEEE: modport_item
		yaID '(' modportPortsDeclList ')'	{ }

modportPortsDeclList:
		modportPortsDecl			{ }
	|	modportPortsDeclList ',' modportPortsDecl	{ }
	;

// IEEE: modport_ports_declaration  + modport_simple_ports_declaration
//	+ (modport_tf_ports_declaration+import_export) + modport_clocking_declaration
// We've expanded the lists each take to instead just have standalone ID ports.
// We track the type as with the V2k series of defines, then create as each ID is seen.
modportPortsDecl:
		port_direction modportSimplePort		{ }
	|	yCLOCKING yaID				{ }
	|	yIMPORT modport_tf_port			{ }
	|	yEXPORT modport_tf_port			{ }
	// Continuations of above after a comma.
	|	modportSimplePort			{ }
	;

//IEEE: modport_simple_port or modport_tf_port, depending what keyword was earlier
modportSimplePort:
		yaID					{ }
	|	'.' yaID '(' ')'			{ }
	|	'.' yaID '(' expr ')'			{ }

modport_tf_port:		// ==IEEE: modport_tf_port
		yaID					{ }
	//|	method_prototype
	;

//************************************************
// Variable Declarations

varDeclList:	varDecl					{ }
	|	varDecl varDeclList			{ }
	;

regsigList:	regsig  				{ }
	|	regsigList ',' regsig		       	{ }
	;

portV2kDecl:	varRESET port_direction v2kVarDeclE signingE regArRangeE portV2kInit	{ }
//	|	varRESET yaID          portV2kSig	{ }
//	|	varRESET yaID '.' yaID portV2kSig	{ }
	;

portDecl:			// IEEE: port_declaration - plus ';'
		varRESET port_direction v2kVarDeclE signingE regArRangeE regsigList ';'	{ }
	;

varDecl:			// IEEE: net_declaration+reg_declaration due to implicit ambiguity
		net_declaration				{ }
	|	data_declaration			{ }
	;

net_declaration:		// IEEE: net_declaration - excluding implict
		varRESET varReg     signingE regArRangeE  regsigList ';'	{ }
	|	varRESET varGParam  signingE regrangeE  paramList ';'		{ }
	|	varRESET varLParam  signingE regrangeE  paramList ';'		{ }
	|	varRESET net_type   strengthSpecE signingE delayrange netSigList ';'	{ }
	|	varRESET varGenVar  signingE                          regsigList ';'	{ }
	|	varRESET enumDecl   sigList ';'		{ }
	;

modParDecl:	varRESET varGParam  signingE regrangeE   param 	{ }
	;

varRESET:	/* empty */ 				{ VARRESET(); }
	;

net_type:			// ==IEEE: net_type  (complete)
		ySUPPLY0				{ VARDECL($1); }
	|	ySUPPLY1				{ VARDECL($1); }
	|	yWIRE 					{ VARDECL($1); }
	|	yTRI 					{ VARDECL($1); }
	|	ygenNETTYPE				{ VARDECL($1); }
	;
varGParam:	yPARAMETER				{ VARDECL($1); }
	;
varLParam:	yLOCALPARAM				{ VARDECL($1); }
	;
varGenVar:	yGENVAR					{ VARDECL($1); }
	;
varReg:		varTypeKwds				{ VARDECL($1); }
	;

port_direction:			// ==IEEE: port_direction
		yINPUT					{ VARIO($1); }
	|	yOUTPUT					{ VARIO($1); }
	|	yINOUT					{ VARIO($1); }
	|	yREF					{ VARIO($1); }
	;

varTypeKwds<str>:
		integer_type				{ $$=$1; }
	|	non_integer_type			{ $$=$1; }
	|	ySTRING					{ $<fl>$=$<fl>1; $$=$1; }
	|	yEVENT					{ $<fl>$=$<fl>1; $$=$1; }
	|	yCHANDLE				{ $<fl>$=$<fl>1; $$=$1; }
	;

// There's no point in subdividing the integer types into atom/vector
// because once we go through a typedef we can't tell them apart.
// Later parsing needs to determine if a range is appropriate or not.
integer_type<str>:		//== IEEE: integer_type (complete)
	//			// IEEE: integer_atom_type (complete)
		yBYTE					{ $<fl>$=$<fl>1; $$=$1; }
	|	ySHORTINT				{ $<fl>$=$<fl>1; $$=$1; }
	|	yINT					{ $<fl>$=$<fl>1; $$=$1; }
	|	yLONGINT				{ $<fl>$=$<fl>1; $$=$1; }
	|	yINTEGER				{ $<fl>$=$<fl>1; $$=$1; }
	|	yTIME					{ $<fl>$=$<fl>1; $$=$1; }
	//			// IEEE: integer_vector_type (complete)
	|	yBIT					{ $<fl>$=$<fl>1; $$=$1; }
	|	yLOGIC					{ $<fl>$=$<fl>1; $$=$1; }
	|	yREG					{ $<fl>$=$<fl>1; $$=$1; }
	;

non_integer_type<str>:		// ==IEEE: non_integer_type (complete)
		ySHORTREAL				{ $<fl>$=$<fl>1; $$=$1; }
	|	yREAL					{ $<fl>$=$<fl>1; $$=$1; }
	|	yREALTIME				{ $<fl>$=$<fl>1; $$=$1; }
	;

signingE:			// IEEE: signing - plus empty (complete)
		/*empty*/ 				{ }
	|	ySIGNED					{ VARSIGNED("signed"); }
	|	yUNSIGNED				{ VARSIGNED("unsigned"); }
	;

v2kVarDeclE:	/*empty*/ 				{ }
	|	net_type				{ }
	|	varReg 					{ }
	;

//************************************************
// Enums

data_type:			// ==IEEE: data_type (INCOMPLETE)
		enumDecl				{ }
//	|	integer_vector_type [ signing ] { packed_dimension }		{ }
//	|	integer_atom_type [ signing ]		{ }
//	|	non_integer_type			{ }
	|	ySTRUCT        packedSigningE '{' struct_union_memberList '}'	{ }
	|	yUNION taggedE packedSigningE '{' struct_union_memberList '}'	{ }
//	|	{ packed_dimension }			{ }
	|	ySTRING					{ }
	|	yCHANDLE				{ }
	|	yVIRTUAL interfaceE yaID		{ }
//	|	[ class_scope | package_scope ] type_identifier { packed_dimension }		 { }
//	|	class_type				{ }
	|	yEVENT					{ }
//	|	ps_covergroup_identifier		{ }
//	|	type_reference				{ }
	;

//IEEE: struct_union - not needed, expanded in data_type

data_type_or_void:		// ==IEEE: data_type_or_void (complete)
		data_type				{ }
	|	yVOID					{ }
	;

struct_union_memberList:
		struct_union_member				{ }
	|	struct_union_memberList struct_union_member	{ }
	;

struct_union_member:		// ==IEEE: struct_union_member
		random_qualifierE data_type_or_void list_of_variable_decl_assignments ';'
	;

list_of_variable_decl_assignments:	// ==IEEE: list_of_variable_decl_assignments
		/*empty*/				{ }
//		FIX lots
	;

interfaceE:
		/*empty*/				{ }
	|	yINTERFACE				{ }
	;

random_qualifierE:		// IEEE: random_qualifier + empty
		/*empty*/				{ }
	|	yRAND					{ }
	|	yRANDC					{ }
	;

taggedE:
		/*empty*/				{ }
	|	yTAGGED					{ }
	;

packedSigningE:
		/*empty*/				{ }
	|	yPACKED signingE			{ }
	;

// IEEE: part of data_type
enumDecl:	yENUM enumBaseTypeE '{' enumNameList '}' { }
	;

enumBaseTypeE:		// IEEE: enum_base_type (complete)
		/* empty */				{ VARDECL("enum"); }
	|	integer_type signingE regrangeE		{ VARDECL($1); }
	|	yaID regrangeE				{ VARDECL($1); }
	;

enumNameList:	enum_name_declaration			{ }
	|	enumNameList ',' enum_name_declaration	{ }
	;

enum_name_declaration:		// ==IEEE: enum_name_declaration
		yaID enumNameRangeE enumNameStartE	{ }
	;

// IEEE: second part of enum_name_declaration
enumNameRangeE:	/* empty */				{ }
	|	'[' yaINTNUM ']'			{ }
	|	'[' yaINTNUM ':' yaINTNUM ']'		{ }
	;

// IEEE: third part of enum_name_declaration
enumNameStartE:	/* empty */				{ }
	|	'=' constExpr				{ }
	;


//************************************************
// Typedef

data_declaration:		// ==IEEE: data_declaration (INCOMPLETE)
//	[ yCONST ] [ yVAR ] lifetimeE data_type_or_implicit list_of_variable_decl_assignments ';'
		type_declaration			{ }
//	|	package_import_declaration
//	|	virtual_interface_declaration
	;

// Needs a lot of work
type_declaration:		// ==IEEE: type_declaration (INCOMPLETE)
		yTYPEDEF data_type yaID variable_dimensionE ';'
//	|	yTYPEDEF yaID '.' yaID yaID ';'
	|	yTYPEDEF yENUM yaID ';'
	|	yTYPEDEF ySTRUCT yaID ';'
	|	yTYPEDEF yUNION yaID ';'
	|	yTYPEDEF yCLASS yaID ';'
	;

variable_dimensionE:
		/* empty */				{ }
//	|	variable_dimension			{ }
	;

//************************************************
// Module Items

modItemListE:
		/* empty */				{ }
	|	modItemList				{ }
	;

modItemList:
		modItem					{ }
	|	modItemList modItem			{ }
	;

modItem:
		modOrGenItem 				{ }
	|	generate_region				{ }
	|	ySPECIFY specifyJunkList yENDSPECIFY	{ }
	|	ySPECIFY yENDSPECIFY			{ }
	;

generate_region:		// ==IEEE: generate_region (complete)
		yGENERATE genTopBlock yENDGENERATE	{ }
	;

// IEEE: ??? + parameter_override
modOrGenItem:
	//			// IEEE: always_construct (complete)
		yALWAYS stmtBlock			{ }
	//			// IEEE: initial_construct (complete)
	|	yINITIAL stmtBlock			{ }
	//			// IEEE: final_construct (complete)
	|	yFINAL stmtBlock			{ }

	|	yASSIGN strengthSpecE delayE assignList ';'	{ }
	|	yDEFPARAM list_of_defparam_assignments ';'	{ }
	|	instDecl 				{ }
	|	taskDecl 				{ }
	|	funcDecl 				{ }
	|	portDecl	 			{ }
	|	varDecl 				{ }
	|	tableDecl 				{ }

	|	concurrent_assertion_item		{ }  // IEEE puts in modItem, all tools put here
	|	clocking_declaration			{ }

	|	error ';'				{ }
	;

//************************************************
// Generates

// Because genItemList includes variable declarations, we don't need beginNamed
genItemBlock:
		genItem					{ }
	|	genItemBegin				{ }
	;

genTopBlock:
		genItemList				{ }
	|	genItemBegin				{ }
	;

genItemBegin:
		yBEGIN genItemList yEND			{ }
	|	yBEGIN yEND				{ }
	|	yBEGIN ':' yaID genItemList yEND endLabelE	{ }
	|	yBEGIN ':' yaID             yEND endLabelE	{ }
	;

genItemList:
		genItem					{ }
	|	genItemList genItem			{ }
	;

genItem:
		modOrGenItem 				{ }
	|	yCASE  '(' expr ')' genCaseListE yENDCASE	{ }
	|	yIF '(' expr ')' genItemBlock	%prec prLOWER_THAN_ELSE	{ }
	|	yIF '(' expr ')' genItemBlock yELSE genItemBlock	{ }
	|	yFOR '(' varRefBase '=' expr ';' expr ';' varRefBase '=' expr ')' genItemBlock
							{ }
	;

genCaseListE:
		/* empty */				{ }
	|	genCaseList				{ }
	;

genCaseList:
		caseCondList ':' genItemBlock		{ }
	|	yDEFAULT ':' genItemBlock		{ }
	|	yDEFAULT genItemBlock			{ }
	|	genCaseList caseCondList ':' genItemBlock	{ }
	|       genCaseList yDEFAULT genItemBlock		{ }
	|	genCaseList yDEFAULT ':' genItemBlock		{ }
	;

//************************************************
// Assignments and register declarations

// IEEE: variable_lvalue
variableLvalue:	varRefDotBit				{ }
	|	'{' concIdList '}'			{ }
	;

assignList:
		assignOne				{ }
	|	assignList ',' assignOne		{ }
	;

assignOne:
		variableLvalue '=' expr			{ }
	;

delayOrEvE:		// IEEE: delay_or_event_control plus empty (complete)
		/* empty */				{ }
	|	delay_control				{ } /* ignored */
	|	event_control				{ } /* ignored */
	|	yREPEAT '(' expr ')' delayOrEvE		{ } /* ignored */
	;

delayE:		/* empty */				{ }
	|	delay_control				{ } /* ignored */
	;

delay_control:		//== IEEE: delay_control (complete)
		'#' dlyTerm				{ } /* ignored */
	|	'#' '(' minTypMax ')'			{ } /* ignored */
	|	'#' '(' minTypMax ',' minTypMax ')'		{ } /* ignored */
	|	'#' '(' minTypMax ',' minTypMax ',' minTypMax ')'	{ } /* ignored */
	;

dlyTerm:
		yaID 					{ }
	|	yaINTNUM 				{ }
	|	yaFLOATNUM 				{ }
	|	yaTIMENUM 				{ }
	;

// IEEE: mintypmax_expression and constant_mintypmax_expression
minTypMax:
		expr 					{ }
	|	expr ':' expr ':' expr			{ }
	;

sigAndAttr<str>:
		sigId sigAttrListE			{ $<fl>$=$<fl>1; $$=$1; }
	;

netSigList:
		netSig  				{ }
	|	netSigList ',' netSig		       	{ }
	;

netSig:
		sigId sigAttrListE			{ }
	|	yaID  sigAttrListE '=' expr		{ VARDONE($<fl>1, $1, $4); }
	|	sigIdRange sigAttrListE			{ }
	;

sigIdRange:
		yaID rangeList				{ $<fl>$=$<fl>1; VARARRAY($2); VARDONE($<fl>1, $1, ""); }
	;

regSigId<str>:
		yaID rangeListE				{ $<fl>$=$<fl>1; VARARRAY($2); VARDONE($<fl>1, $1, ""); }
	|	yaID rangeListE '=' constExpr		{ $<fl>$=$<fl>1; VARARRAY($2); VARDONE($<fl>1, $1, $4); }
	;

sigId<str>:
		yaID					{ $<fl>$=$<fl>1; VARDONE($<fl>1, $1, ""); }
	;

sigList:	sigInit					{ }
	|	sigList ',' sigInit			{ }
	;

sigInit:	sigAndAttr				{ }
	|	sigAndAttr '=' expr			{ }
	;

regsig:		regSigId sigAttrListE			{}
	;

sigAttrListE:	/* empty */				{}
	;

rangeListE<str>:
		/* empty */    		               	{ $$ = ""; }
	|	rangeList 				{ $$ = $1; }
	;

rangeList<str>:
		anyrange				{ $$ = $1; }
        |	rangeList anyrange			{ $$ = $1+$2; }
	;

regrangeE<str>:
		/* empty */    		               	{ VARRANGE(""); }
	|	anyrange 				{ VARRANGE($1); }
	;

regArRangeE:	/* empty */    		               	{ }
	|	regArRangeList 				{ }
	;

// Complication here is "[#:#]" is a range, while "[#:#][#:#]" is an array and range.
regArRangeList:	anyrange				{ VARRANGE($1); }
        |	regArRangeList anyrange			{ VARARRAY(GRAMMARP->m_varArray+GRAMMARP->m_varRange); VARRANGE($2); }
	;

anyrange<str>:
		'[' constExpr ':' constExpr ']'		{ $$ = "["+$2+":"+$4+"]"; }
	;

delayrange:
		regrangeE delayE 			{ }
	|	ySCALARED regrangeE delayE 		{ }
	|	yVECTORED regrangeE delayE		{ }
	;

portRangeE<str>:
		/* empty */	                   	{ $$ = ""; }
	|	'[' constExpr ']'              		{ $$ = "["+$2+"]"; }
	|	'[' constExpr ':' constExpr  ']'    	{ $$ = "["+$2+":"+$4+"]"; }
	;

//************************************************
// Parameters

param:		yaID sigAttrListE '=' expr		{ $<fl>$=$<fl>1; VARDONE($<fl>1, $1, $4); }
	;

paramList:	param					{ }
	|	paramList ',' param			{ }
	;

list_of_defparam_assignments:	//== IEEE: list_of_defparam_assignments (complete)
		defparam_assignment					{ }
	|	list_of_defparam_assignments ',' defparam_assignment	{ }
	;

defparam_assignment:		// ==IEEE: defparam_assignment (complete)
		varRefDotBit '=' expr 		{ }
	;

//************************************************
// Instances
// We don't know if its a gate or module instantiation
//   modname        [#(params)]  name  (pins) [, name ...]
//   gate (strong0) [#(delay)]  [name] (pins) [, (pins)...]

instDecl:
		instModName {INSTPREP($1,1);} strengthSpecE instparamListE {INSTPREP($1,0);} instnameList ';' 	{ }
	;

instModName<str>:
		yaID 					{ $<fl>$=$<fl>1; $$ = $1; }
	|	gateKwd			 		{ $<fl>$=$<fl>1; $$ = $1; }
	;

instparamListE:
		/* empty */				{ }
	|	'#' '(' cellpinList ')'			{ }
	|	'#' dlyTerm				{ }
	;

instnameList:
		instnameParen				{ }
	|	instnameList ',' instnameParen		{ }
	;

instnameParen:
		instname cellpinList ')'		{ PARSEP->endcellCb($<fl>3,""); }
	;

instname:	yaID instRangeE '(' 			{ PARSEP->instantCb($<fl>1, GRAMMARP->m_cellMod, $1, $2); PINPARAMS(); }
	|	instRangeE '(' 				{ PARSEP->instantCb($<fl>2, GRAMMARP->m_cellMod, "", $1); PINPARAMS(); } // UDP
	;

instRangeE<str>:
		/* empty */				{ $$ = ""; }
	|	'[' constExpr ':' constExpr ']'		{ $$ = "["+$2+":"+$4+"]"; }
	;

cellpinList:
		{ } cellpinItList			{ }
	;

cellpinItList:
		cellpinItemE				{ }
	|	cellpinItList ',' cellpinItemE		{ }
	;

cellpinItemE:
		/* empty: ',,' is legal */		{ GRAMMARP->pinNumInc(); }  /*PINDONE(yylval.fl,"",""); <- No, as then () implys a pin*/
	|	yP_DOTSTAR				{ PINDONE($<fl>1,"*","*");GRAMMARP->pinNumInc(); }
	|	'.' yaID				{ PINDONE($<fl>1,$2,$2);  GRAMMARP->pinNumInc(); }
	|	'.' yaID '(' ')'			{ PINDONE($<fl>1,$2,"");  GRAMMARP->pinNumInc(); }
	|	'.' yaID '(' expr ')'			{ PINDONE($<fl>1,$2,$4);  GRAMMARP->pinNumInc(); }
	|	expr					{ PINDONE($<fl>1,"",$1);  GRAMMARP->pinNumInc(); }
	;

//************************************************
// EventControl lists

event_control:			// ==IEEE: event_control
		'@' '(' senList ')'			{ }
	|	'@' senitemVar				{ }
	|	'@' '(' '*' ')'				{ }
	|	'@' '*'					{ }  /* Verilog 2001 */
//	|	sequence_instance			{ }
	;

senList:			// IEEE: event_expression - split over several (complete)
		senitem					{ }
	|	senList yOR senitem			{ }
	|	senList ',' senitem			{ }	/* Verilog 2001 */
	;

senitem:
		senitemEdge				{ }
	|	expr					{ }
	;

senitemVar:
		varRefDotBit				{ }
	;

senitemEdge:			// IEEE: part of event_expression
		yPOSEDGE expr				{ }
	|	yPOSEDGE expr yIFF expr			{ }
	|	yNEGEDGE expr				{ }
	|	yNEGEDGE expr yIFF expr			{ }
	;

//************************************************
// Statements

// IEEE: statement + seq_block + par_block
stmtBlock:	stmt					{ }
	|	yBEGIN stmtList yEND			{ }
	|	yBEGIN yEND				{ }
	|	beginNamed stmtList yEND endLabelE	{ }
	|	beginNamed 	    yEND endLabelE	{ }
	|	yFORK stmtList	   yJOIN		{ }
	|	yFORK 		   yJOIN		{ }
	|	forkNamed stmtList yJOIN endLabelE	{ }
	|	forkNamed 	   yJOIN endLabelE	{ }
	;

beginNamed:
		yBEGIN ':' yaID varDeclList		{ }
	|	yBEGIN ':' yaID 			{ }
	;

forkNamed:
		yFORK ':' yaID varDeclList		{ }
	|	yFORK ':' yaID 				{ }
	;

stmtList:
		stmtBlock				{ }
	|	stmtList stmtBlock			{ }
	;

assignLhs<str>:
		varRefDotBit				{ $<fl>$=$<fl>1; $$ = $1; }
	|	'{' concIdList '}'			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	;

// IEEE: statement_or_null (may include more stuff, not analyzed)
stmt:
		';'					{ }
	|	labeledStmt				{ }
	|	yaID ':' labeledStmt			{ }  /*S05 block creation rule*/

	|	assignLhs yP_LTE	delayOrEvE expr ';'	{ }
	|	assignLhs '=' 		delayOrEvE expr ';'	{ }
	|	assignLhs yP_PLUSEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_MINUSEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_TIMESEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_DIVEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_MODEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_ANDEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_OREQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_XOREQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_SLEFTEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_SRIGHTEQ	delayOrEvE expr ';'	{ }
	|	assignLhs yP_SSRIGHTEQ	delayOrEvE expr ';'	{ }

	|	varRefDotBit yP_PLUSPLUS 		{ }
	|	varRefDotBit yP_MINUSMINUS 		{ }
	|	yP_PLUSPLUS	varRefDotBit		{ }
	|	yP_MINUSMINUS	varRefDotBit		{ }

	|	stateCaseForIf				{ }
	|	taskRef ';' 				{ }

	|	yFOREVER stmtBlock			{ }

	|	yP_MINUSGT expr ';' 			{ }  /* event trigger */
	|	ygenSYSCALL '(' ')' ';'			{ }
	|	ygenSYSCALL '(' exprList ')' ';'	{ }
	|	ygenSYSCALL ';'				{ }
	|	delay_control stmtBlock			{ }
	|	event_control stmtBlock			{ }

	//			// IEEE: disable_statement (complete)
	|	yDISABLE expr ';'			{ }
	|	yDISABLE yFORK ';'			{ }

	//			// IEEE: procedural_continuous_assignment (complete)
	|	yASSIGN expr '=' delayOrEvE expr ';'	{ }
	|	yDEASSIGN expr ';'			{ }
	|	yFORCE expr '=' expr ';'		{ }
	|	yRELEASE expr ';'			{ }

	//			// IEEE: jump_statement (complete)
	|	yRETURN ';'				{ }
	|	yRETURN expr ';'			{ }
	|	yBREAK ';'				{ }
	|	yCONTINUE ';'				{ }

	|	error ';'				{ }
	;

//************************************************
// Case/If

unique_priorityE:
		/*empty*/				{ }
	|	yPRIORITY				{ }
	|	yUNIQUE					{ }
	;

stateCaseForIf:
		caseStmt caseAttrE caseListE yENDCASE	{ }
	//			// IEEE: randcase_statement (complete)
	|	yRANDCASE caseList yENDCASE		{ }
	//			// IEEE: conditional_statement
	|	unique_priorityE yIF '(' expr ')' stmtBlock	%prec prLOWER_THAN_ELSE	{ }
	|	unique_priorityE yIF '(' expr ')' stmtBlock yELSE stmtBlock		{ }

	|	yFOR '(' assignLhs '=' expr ';' expr ';' assignLhs '=' expr ')' stmtBlock
							{ }
	|	yWHILE '(' expr ')' stmtBlock		{ }
	|	yDO stmtBlock yWHILE '(' expr ')'	{ }
	|	yREPEAT '(' expr ')' stmtBlock		{ }
	|	yWAIT '(' expr ')' stmtBlock		{ }
	;

caseStmt:
	 	unique_priorityE yCASE  '(' expr ')'	{ }
	|	unique_priorityE yCASEX '(' expr ')'	{ }
	|	unique_priorityE yCASEZ '(' expr ')'	{ }
	;

caseAttrE: 	/*empty*/				{ }
	;

caseListE:	/* empty */				{ }
	|	caseList				{ }
	;

caseList:
		caseCondList ':' stmtBlock		{ }
	|	yDEFAULT ':' stmtBlock			{ }
	|	yDEFAULT stmtBlock			{ }
	|	caseList caseCondList ':' stmtBlock	{ }
	|       caseList yDEFAULT stmtBlock		{ }
	|	caseList yDEFAULT ':' stmtBlock		{ }
	;

caseCondList:
		expr 					{ }
	|	caseCondList ',' expr			{ }
	;

//************************************************
// Functions/tasks

taskRef:
		idDotted		 		{ }
	|	idDotted '(' exprList ')'		{ }
	;

funcRef<str>:
		idDotted '(' exprList ')'		{ $1+"("+$3+")"; }
	;

taskDecl:
	 	yTASK lifetimeE taskId funcGuts yENDTASK endLabelE
			{ GRAMMARP->m_inFTask=false; PARSEP->endtaskfuncCb($<fl>5,$5); }
	;

funcDecl:
	 	yFUNCTION lifetimeE funcId funcGuts yENDFUNCTION endLabelE
			{ GRAMMARP->m_inFTask=false; PARSEP->endtaskfuncCb($<fl>5,$5); }
	;

lifetimeE:			// IEEE: lifetime - plus empty (complete)
		/* empty */		 		{ }
	|	ySTATIC			 		{ }
	|	yAUTOMATIC		 		{ }
	;

taskId:		yaID 					{ GRAMMARP->m_inFTask=true; PARSEP->taskCb($<fl>1,"task",$1); }
	;

funcId: 	funcTypeE yaID				{ GRAMMARP->m_inFTask=true; PARSEP->functionCb($<fl>2,"function",$2,$1); }
	|	ySIGNED funcTypeE yaID			{ GRAMMARP->m_inFTask=true; PARSEP->functionCb($<fl>3,"function",$3,"signed "+$2); }
	;

funcGuts:
		'(' {GRAMMARP->pinNum(1);} portV2kArgs ')' ';' funcBody	{ }
	|	';' funcBody				{ }
	;

funcBody:
		funcVarList stmtBlock			{ }
	|	stmtBlock				{ }
	;

funcTypeE<str>:
		/* empty */				{ $$ = ""; }
	|	varTypeKwds				{ $$ = $1; }
	|	'[' constExpr ':' constExpr ']'		{ $$ = "["+$2+":"+$4+"]"; }
	;

funcVarList:
		funcVar					{ }
	|	funcVarList funcVar			{ }
	;

funcVar:
	 	portDecl				{ }
	|	varDecl 				{ }
	;

//************************************************
// Expressions

constExpr<str>:
		expr					{ $<fl>$=$<fl>1; $$ = $1; }
	;

exprNoStr<str>:
		expr yP_OROR expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_ANDAND expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '&' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '|' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_NAND expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_NOR expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '^' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_XNOR expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_EQUAL expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_NOTEQUAL expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_CASEEQUAL expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_CASENOTEQUAL expr		{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_WILDEQUAL expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_WILDNOTEQUAL expr		{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '>' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '<' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_GTE expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_LTE expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_SLEFT expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_SRIGHT expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_SSRIGHT expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '+' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '-' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '*' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '/' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr '%' expr				{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }
	|	expr yP_POW expr			{ $<fl>$=$<fl>1; $$ = $1+$2+$3; }

	|	'-' expr	%prec prUNARYARITH	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'+' expr	%prec prUNARYARITH	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'&' expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'|' expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'^' expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	yP_XNOR expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	yP_NAND expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	yP_NOR expr	%prec prREDUCTION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'!' expr	%prec prNEGATION	{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	'~' expr	%prec prNEGATION	{ $<fl>$=$<fl>1; $$ = $1+$2; }

	|	varRefDotBit yP_PLUSPLUS		{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	varRefDotBit yP_MINUSMINUS		{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	yP_PLUSPLUS	varRefDotBit		{ $<fl>$=$<fl>1; $$ = $1+$2; }
	|	yP_MINUSMINUS	varRefDotBit		{ $<fl>$=$<fl>1; $$ = $1+$2; }

	|	expr '?' expr ':' expr			{ $<fl>$=$<fl>1; $$ = $1+"?"+$3+":"+$5; }
	|	'(' expr ')'				{ $<fl>$=$<fl>1; $$ = "("+$2+")"; }
	|	'_' '(' statePushVlg expr statePop ')'	{ $<fl>$=$<fl>1; $$ = "_("+$4+")"; }	// Arbitrary Verilog inside PSL
	|	'{' cateList '}'			{ $<fl>$=$<fl>1; $$ = "{"+$2+"}"; }
	|	'{' constExpr '{' cateList '}' '}'	{ $<fl>$=$<fl>1; $$ = "{"+$2+"{"+$4+"}}"; }

	|	ygenSYSCALL				{ $<fl>$=$<fl>1; $$ = $1; }
	|	ygenSYSCALL '(' ')'			{ $<fl>$=$<fl>1; $$ = $1; }
	|	ygenSYSCALL '(' exprList ')'		{ $<fl>$=$<fl>1; $$ = $1+"("+$3+")"; }

	|	funcRef					{ $<fl>$=$<fl>1; $$ = $1; }

	|	yaINTNUM				{ $<fl>$=$<fl>1; $$ = $1; }
	|	yaFLOATNUM				{ $<fl>$=$<fl>1; $$ = $1; }
	|	yaTIMENUM				{ $<fl>$=$<fl>1; $$ = $1; }

	|	varRefDotBit	  			{ $<fl>$=$<fl>1; $$ = $1; }
	;

// Generic expressions
expr<str>:
		exprNoStr				{ $<fl>$=$<fl>1; $$ = $1; }
	|	strAsInt				{ $<fl>$=$<fl>1; $$ = $1; }
	;

cateList<str>:
		expr					{ $<fl>$=$<fl>1; $$ = $1; }
	|	cateList ',' expr			{ $<fl>$=$<fl>1; $$ = $1+","+$3; }
	;

exprList<str>:
		expr					{ $<fl>$=$<fl>1; $$ = $1; }
	|	exprList ',' expr			{ $<fl>$=$<fl>1; $$ = $1+","+$3; }
	|	exprList ','				{ $<fl>$=$<fl>1; $$ = $1+","; }   // Verilog::Parser only: ,, is ok
	;

//************************************************
// Gate declarations

// We can't tell between UDPs and modules as they aren't declared yet.
// For simplicity, assume everything is a module, perhaps nameless,
// and deal with it later.

// IEEE: cmos_switchtype + enable_gatetype + mos_switchtype
//	+ n_input_gatetype + n_output_gatetype + pass_en_switchtype
//	+ pass_switchtype
gateKwd<str>:
		ygenGATE				{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yAND					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	| 	yBUF					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yNAND					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yNOR					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yNOT					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yOR					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yXNOR					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	|	yXOR					{ $<fl>$=$<fl>1; INSTPREP($1,0); }
	;

// This list is also hardcoded in VParseLex.l
// IEEE: strength0+strength1 - plus HIGHZ/SMALL/MEDIUM/LARGE
strength:	ygenSTRENGTH				{ }
	|	ySUPPLY0				{ }
	|	ySUPPLY1				{ }
	;

// IEEE: drive_strength + pullup_strength + pulldown_strength
//	+ charge_strength - plus empty
strengthSpecE:	/* empty */					{ }
	|	yP_PARSTRENGTH strength ')'			{ }
	|	yP_PARSTRENGTH strength ',' strength ')'	{ }
	;

//************************************************
// Tables

tableDecl:	yTABLE specifyJunkList yENDTABLE	{ }

//************************************************
// Specify

specifyJunkList:	specifyJunk 			{} /* ignored */
	|	specifyJunkList specifyJunk		{} /* ignored */
	;

specifyJunk:	dlyTerm 	{} /* ignored */
	|	';' {}
	|	'!' {}
	|	'&' {}
	|	'(' {}
	|	')' {}
	|	'*' {} | '/' {} | '%' {}
	|	'+' {} | '-' {}
	|	',' {}
	|	':' {}
	|	'$' {}
	|	'=' {}
	|	'>' {} | '<' {}
	|	'?' {}
	|	'^' {}
	|	'{' {} | '}' {}
	|	'[' {} | ']' {}
	|	'|' {}
	|	'~' {}
	|	'@' {}

	|	yIF {}
	|	yNEGEDGE {}
	|	yPOSEDGE {}

	|	yaSTRING {}
	|	yaTIMINGSPEC {}
	|	ygenSYSCALL {}

	|	yP_ANDAND {} | yP_GTE {} | yP_LTE {}
	|	yP_EQUAL {} | yP_NOTEQUAL {}
	|	yP_CASEEQUAL {} | yP_CASENOTEQUAL {}
	|	yP_WILDEQUAL {} | yP_WILDNOTEQUAL {}
	|	yP_XNOR {} | yP_NOR {} | yP_NAND {}
	|	yP_OROR {}
	|	yP_SLEFT {} | yP_SRIGHT {} | yP_SSRIGHT {}
	|	yP_PLUSCOLON {} | yP_MINUSCOLON {}
	|	yP_POW {}
	|	yP_MINUSGT {}
	|	yP_EQGT {}	| yP_ASTGT {}
	|	yP_ANDANDAND {}
	|	yP_MINUSGTGT {}
	|	yP_POUNDPOUND {}
	|	yP_DOTSTAR {}
	|	yP_ATAT {}
	|	yP_COLONCOLON {}
	|	yP_COLONEQ {}
	|	yP_COLONDIV {}
	|	yP_ORMINUSGT {}
	|	yP_OREQGT {}

	|	yP_PLUSPLUS {}	| yP_MINUSMINUS {}
	|	yP_PLUSEQ {}	| yP_MINUSEQ {}
	|	yP_TIMESEQ {}
	|	yP_DIVEQ {}	| yP_MODEQ {}
	|	yP_ANDEQ {}	| yP_OREQ {}
	|	yP_XOREQ {}
	|	yP_SLEFTEQ {}	| yP_SRIGHTEQ {} | yP_SSRIGHTEQ {}

	|	error {}
	;

//************************************************
// IDs

// VarRef to dotted, and/or arrayed, and/or bit-ranged variable
varRefDotBit<str>:
		idDotted				{ $<fl>$=$<fl>1; $$ = $1; }
	;

idDotted<str>:
		idArrayed 				{ $<fl>$=$<fl>1; $$ = $1; }
	|	idDotted '.' idArrayed	 		{ $<fl>$=$<fl>1; $$ = $1+"."+$3; }
	;

// Single component of dotted path, maybe [#].
// Due to lookahead constraints, we can't know if [:] or [+:] are valid (last dotted part),
// we'll assume so and cleanup later.
idArrayed<str>:
		yaID						{ $<fl>$=$<fl>1; $$ = $1; }
	|	idArrayed '[' expr ']'				{ $<fl>$=$<fl>1; $$ = $1+"["+$3+"]"; }
	|	idArrayed '[' constExpr ':' constExpr ']'	{ $<fl>$=$<fl>1; $$ = $1+"["+$3+":"+$5+"]"; }
	|	idArrayed '[' expr yP_PLUSCOLON  constExpr ']'	{ $<fl>$=$<fl>1; $$ = $1+"["+$3+"+:"+$5+"]"; }
	|	idArrayed '[' expr yP_MINUSCOLON constExpr ']'	{ $<fl>$=$<fl>1; $$ = $1+"["+$3+"-:"+$5+"]"; }
	;

// VarRef without any dots or vectorizaion
varRefBase<str>:
		yaID					{ $<fl>$=$<fl>1; $$ = $1; }
	;

strAsInt<str>:
		yaSTRING				{ $<fl>$=$<fl>1; $$ = $1; }
	;

concIdList<str>:
		varRefDotBit				{ $<fl>$=$<fl>1; $$ = $1; }
	|	concIdList ',' varRefDotBit		{ $<fl>$=$<fl>1; $$ = $1+","+$3; }
	;

endLabelE:	/* empty */				{ }
	|	':' yaID				{ }
	;

//************************************************
// Asserts

labeledStmt:
		assertStmt				{ }
	;

clocking_declaration:		// IEEE: clocking_declaration  (INCOMPLETE)
		yDEFAULT yCLOCKING '@' '(' senList ')' ';' yENDCLOCKING  {}
	;

concurrent_assertion_item:	// IEEE: concurrent_assertion_item  (complete)
		concurrent_assertion_statement		{ }
	|	yaID ':' concurrent_assertion_statement	{ }
	;

concurrent_assertion_statement:	// IEEE: concurrent_assertion_statement  (INCOMPLETE)
		cover_property_statement		{ }
	;

cover_property_statement:	// IEEE: cover_property_statement (complete)
		yCOVER yPROPERTY '(' property_spec ')' stmtBlock	{ }
	;

property_spec:			// IEEE: property_spec
		'@' '(' senitemEdge ')' property_spec_disable expr	{ }
	|	property_spec_disable expr	 			{ }
	;

property_spec_disable:
		/* empty */				{ }
	|	yDISABLE yIFF '(' expr ')'		{ }
	;


assertStmt:
		yASSERT '(' expr ')' stmtBlock %prec prLOWER_THAN_ELSE	{ }
	|	yASSERT '(' expr ')'           yELSE stmtBlock		{ }
	|	yASSERT '(' expr ')' stmtBlock yELSE stmtBlock		{ }
	;

//**********************************************************************
// Class

virtualE:
		/* empty */				{ }
	|	yVIRTUAL				{ }
	;

class_declaration:	//== IEEE: class_declaration (INCOMPLETE)
		virtualE yCLASS lifetimeE yaID parameter_port_listE classExtendsE ';'
			class_itemListE
			yENDCLASS endLabelE {
			PARSEP->unsupportedCb($<fl>4, "Unsupported class", "class"); }
	;

classExtendsE:		// IEEE: part of class_declaration
		/* empty */				{ }
	|	yEXTENDS yaID 				{ }
//	|	yEXTENDS yaID '(' list_of_arguments ')'	{ }
	;

class_itemListE:
		/* empty */				{ }
	|	class_itemList				{ }
	;

class_itemList:
		class_item				{ }
	|	class_itemList class_item  		{ }
	;

class_item:		//== IEEE: class_item (UNSUPPORTED)
		BISONPRE_NOT(yCLASS,yENDCLASS)		{ }
	|	yCLASS class_itemListE yENDCLASS	{ }
	;

//**********************************************************************
%%

int VParseGrammar::parse() {
    s_grammarp = this;
    return VParseBisonparse();
}
void VParseGrammar::debug(int level) {
    VParseBisondebug = level;
}
const char* VParseGrammar::tokenName(int token) {
#if YYDEBUG || YYERROR_VERBOSE
    if (token >= 255)
	return yytname[token-255];
    else {
	static char ch[2];  ch[0]=token; ch[1]='\0';
	return ch;
    }
#else
    return "";
#endif
}
