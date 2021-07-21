%{
// #include <stdio.h>      /* For I/O                                 */
// #include <stdlib.h>     /* For malloc here and in symbol table     */
// #include <string.h>     /* For strcmp in symbol table              */
// #include "st.h"         /* Symbol Table                            */
// #include "sm.h"         /* Stack Machine                           */
// #include "codegen.h"         /* Code Generator                          */
#include "shared_headers.h"

int yyerror(char* msg);
int yylex(void);
//global vars
string complex_errors;
extern int num_column;
extern int num_lines;
extern char* yytext; 

// name, index, container
int valprm = 0;
int tmpvar = 0;
int lblnos = 0;
//locals
string tmps;
bool addcheck = false; 
stringstream ssm;
// two approaches, stripping underscores from label putting each character in to_string temp count then setting up a set of two strings for feu/vars, but i'd have to create new var.s
// last attempt here, will go with first/easier approach of simple stack/vector<string> of everything by hand LOL
// vector<string> fwords = { "FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY","END_BODY","INTEGER","ARRAY","OF","IF","THEN", "ENDIF,"ELSE","WHILE", "DO","FOR","BEGINLOOP","ENDLOOP","CONTINUE", "READ", "WRITE", "AND", "OR", "TRUE", "FALSE", "RETURN", "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "IDENT", "NUMBER", "EQ", "NEQ", "LT", "GT, "LTE", "GTE", "SUB", "ADD", "MULT", "DIV", "MOD", "NOT", "ASSIGN", "UMINUS" };
//vector by hand:
stack <string> fparamsq, rseqq;
vector<string> feutbl, prmtbl, symtbl, symtyp, arop, irtmp;
vector<vector> <string> > if_store, loops_store;

%}
%union{
  int noval;
  string* opval;
  // struct semval_exp{
  //   char *r_index, *arr_size, *arr_name, *arr_chk;
  //   bool arr_code;
  // } exp;
  // use multiple structures to hold different tokens
  // struct semval_cmp{
  //   char *op_ptr;
  // } cmp;
  // struct semval_stmt{
  //   char *r_index, *arr_size, *arr_name, *arr_chk;
  //   bool arr_code;
  // } stm;
}

%start Program
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO FOR BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR TRUE FALSE RETURN SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN UMINUS
// %token SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET EQ NEQ LT GT LTE GTE SUB ADD MULT DIV MOD NOT ASSIGN UMINUS
%token<noval> NUMBER
%token<opval> IDENTS
%left MULT DIV MOD ADD SUB
%left LT LTE GT GTE EQ NEQ
%right NOT
%left AND OR
%right ASSIGN
// %type<stm> Program FUNCTION

  /* ------------------------------ GRAMMAR START ----------------------------- */
%%
Program: functions
;
functions: // epsilon
        | function functions
        ;
feulabel: FUNCTION IDENTS { feutbl.push_back(*($2));
  cout << "feu " <<*($2) << endl; }
;
function: feulabel SEMICOLON beginparamsa declarations endparam BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
{
    for(unsigned int j = 0; j < symtbl.size(); j++ ) {
        if (symtyp.at(j) == "INTEGER") {
            std::cout << "show symtbl at " symtbl.at(j) << std::endl; 
        } else {
            std::cout << "info: " << symtbl.at(j) << "and " << symtyp.at(j) << std::endl;
        }
    } //end for loop
    while (!prmtbl.empty()) {
            std::cout << "param = " << prmtbl.front() << ", value: " << valprm << std::endl;
            prmtbl.erase(prmtbl.begin());
            valprm++;
    } // end while loop
    for (unsigned int i = 0 ; i < irtmp.size(); i++) {
        std::cout << irtmp.at(i) << std::endl;
        }
        std::cout "endfunc" << std::endl;
        // re - initialize before ending loop
        symtbl.clear();
        symtyp.clear();
        prmtbl.clear();
        irtmp.clear();
        valprm = 0;
}
;
beginparamsa: BEGIN_PARAMS { addcheck = true; }
;
endparamsa: END_PARAMS { addcheck = false; }
;

declarations: 
        | declaration SEMICOLON declarations
;
declaration: id COLON ASSIGN
;
id: IDENTS {
    sym_table.push_back("_" +* ($1));
    if(addcheck) {
        prmtbl.push_back("_" +* ($1));
    }
}
    | IDENTS COMMA id {
        symtbl.push_back("_" +* ($1));
        symtyp.push_back("INTEGER");
    }
;
assign: INTEGER {
    symtyp.push_back("INTEGER");
}
        | ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
            stringstream ssm1;
            ssm1 << $3;
            string s1 = ssm1.str();
            symtyp.push_back(s);
        }
;
statements: statement SEMICOLON statements
    | statement SEMICOLON
;
statement: type1
| type2 
| type3
| type4
| type5
| type6
| type7
| type8
;

if-expr: IF bool-expr THEN {
    lblnos++; // incrememnt lables per statement
    vector<string> tmpv;
    ssm.str("");
    ssm.clear();
    ssm << lblnos;
    string tmp1 = "if_condition_true_" + ssm.str(), tmp2 = "if_condition_false_" + ssm.str(), tmp3 = "end_if_" + ssm.str();
    tmpv.push_back(tmp1);
    tmpv.push_back(tmp2);
    tmpv.push_back(tmp3);
    ifstr.push_back(tmpv);
    irtmp.push_back("?:= " + ifstr.back().at(0) + ", " + arop.back());
    arop.pop_back();
    irtmp.push_back(":=" + ifstr.back().at(1));
    irtmp.push_back(": " + ifstr.back().at(0));
}
;
elseif: if-expr statements ELSE {
    irtmp.push_back(":= " + ifstr.back().at(2));
    irtmp.push_back(": " + ifstr.back().at(1));
}
;
while-run: WHILE {
    lblnos++; // incrememnt lables per statement
    vector<string> tmpv;
    ssm.str("");
    ssm.clear();
    ssm << lblnos;
    string tmp1 = "while_loop_" + ssm.str(), tmp2 = "conditional_true_" + ssm.str(), tmp3 = "conditional_false_" + ssm.str();
    tmpv.push_back(tmp1);
    tmpv.push_back(tmp2);
    tmpv.push_back(tmp3);
    loopstr.push_back(tmpv);
    irtmp.push_back(": " + loopstr.back().at(0));
}
;
while-expr: while-run bool-expr BEGINLOOP {
    irtmp.push_back("?:= " + loopstr.back().at(1) + ", " + arop.back());
    arop.pop_back();
    irtmp.push_back(":= " + loopstr.back().at(2));
    irtmp.push_back(": " + loopstr.back().at(1));
}
;
do-run: DO BEGINLOOP {
    lblnos++; // incrememnt lables per statement
    vector<string> tmpv;
    ssm.str("");
    ssm.clear();
    ssm << lblnos;
    string tmp1 = "do_while_loop_" + ssm.str(), tmp2 = "do_while_conditional_check" + ssm.str();
    tmpv.push_back(tmp1);
    tmpv.push_back(tmp2);
    loopstr.push_back(tmpv);
    irtmp.push_back(": " + tmp1);
}
;
do-expr: do-run statements ENDLOOP {
    irtmp.push_back(": " + loopstr.back().at(1));
}
;
read-mult: COMMA IDENTS read-mult {
    string var = "_" +* ($2);
    if (!sym_table(var)) {
        exit(0);
    }
    rseqq.push(".< _" +* ($2));
    }
    | COMMA IDENTS L_SQUARE_BRACKET expression R_SQUARE_BRACKET read-mult {
        string var = "_" +* ($2);
        if (!arr_table(var)) {
            exit(0);
        }
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        string new_tmpvar = 't' + ssm.str();
        tmpvar++;
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        rseqq.push(".<" + new_tmpvar);
        rseqq.push("[]= _" +* ($2) + "," + arop.back() + ", " + new_tmpvar);
        arop.pop_back();
    }
    |
;
bool-expr: relation-exprz
    | bool-expr OR relation-exprz { 
        vector<string> tmpv;
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("|| " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
;
relation-exprz: relation-expr
        | relation-exprz AND relation-expr {
            ssm.str("");
            ssm.clear();
            ssm << tmpvar;
            tmpvar++;
            string new_tmpvar = 't' + ssm.str();
            symtbl.push_back(new_tmpvar);
            symtyp.push_back("INTEGER");
            string op_a = arop.back();
            arop.pop_back();
            string op_b = arop.back();
            arop.pop_back();
            irtmp.push_back("&& " + new_tmpvar + ", " + op_a + ", " + op_b);
            arop.push_back(new_tmpvar); 
        }
;
relation-expr: rexpr
    | NOT rexpr {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        irtmp.push_back("! " + new_tmpvar + ", " + op_a);
        arop.push_back(new_tmpvar);
    }
;
rexpr: expression EQ expression {
    ssm.str("");
    ssm.clear();
    ssm << tmpvar;
    tmpvar++;
    string new_tmpvar = 't' + ssm.str();
    symtbl.push_back(new_tmpvar);
    symtyp.push_back("INTEGER");
    string op_a = arop.back();
    arop.pop_back();
    string op_b = arop.back();
    arop.pop_back();
    irtmp.push_back("== " + new_tmpvar + ", " + op_a + ", " + op_b);
    arop.push_back(new_tmpvar);
    }
    | expression NEQ expression {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("!= " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | expression LT expression {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("< " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | expression GT expression {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("> " _ new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | expression LTE expression {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("<= " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | expression GTE expression {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back(">= " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | TRUE {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        irtmp.push_back("= " + new_tmpvar + ", 1");
        arop.push_back(new_tmpvar);
    }
    | FALSE {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        irtmp.push_back("= " + new_tmpvar + ", 0");
        arop.push_back(new_tmpvar);
    }
    | L_PAREN bool-expr R_PAREN
;
expression: mult-expr expr-add
;
expr-add: 
    | ADD mult-expr expr-add {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("+ " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
    | SUB mult-expr expr-add {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        string op_a = arop.back();
        arop.pop_back();
        string op_b = arop.back();
        arop.pop_back();
        irtmp.push_back("- " + new_tmpvar + ", " + op_a + ", " + op_b);
        arop.push_back(new_tmpvar);
    }
;
mult-expr: term mult-termz
;
mult-termz: 
        | MULT term mult-termz {
            ssm.str("");
            ssm.clear();
            ssm << tmpvar;
            tmpvar++;
            string new_tmpvar = 't' + ssm.str();
            symtbl.push_back(new_tmpvar);
            symtyp.push_back("INTEGER");
            string op_a = arop.back();
            arop.pop_back();
            string op_b = arop.back();
            arop.pop_back();
            irtmp.push_back("* " + new_tmpvar + ", " + op_a + ", " + op_b);
            arop.push_back(new_tmpvar);
        }
        | DIV term mult-termz {
            ssm.str("");
            ssm.clear();
            ssm << tmpvar;
            tmpvar++;
            string new_tmpvar = 't' + ssm.str();
            symtbl.push_back(new_tmpvar);
            symtyp.push_back("INTEGER");
            string op_a = arop.back();
            arop.pop_back();
            string op_b = arop.back();
            arop.pop_back();
            irtmp.push_back("/ " + new_tmpvar + ", " + op_a + ", " + op_b);
            arop.push_back(new_tmpvar);
        }
        | MOD term mult-termz { 
            ssm.str("");
            ssm.clear();
            ssm << tmpvar;
            tmpvar++;
            string new_tmpvar = 't' + ssm.str();
            symtbl.push_back(new_tmpvar);
            symtyp.push_back("INTEGER");
            string op_a = arop.back();
            arop.pop_back();
            string op_b = arop.back();
            arop.pop_back();
            irtmp.push_back("% " + new_tmpvar + ", " + op_a + ", " + op_b);
            arop.push_back(new_tmpvar);
        }
;
term: postf { }
    | SUB postf {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        irtmp.push_back("- " + new_tmpvar + ", 0 " + arop.back() );
        arop.pop_back();
        arop.push_back(new_tmpvar)
    }
    | IDENTS term-id {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        if (!feu_table(*($1))) {
            exit(0);
        }
        irtmp.push_back("call " +* ($1) + ", " + new_tmpvar);
        arop.push_back(new_tmpvar);
    }
;
postf: var { 
    ssm.str("");
    ssm.clear();
    ssm << tmpvar;
    tmpvar++;
    string new_tmpvar = 't' + ssm.str();
    symtbl.push_back(new_tmpvar);
    symtyp.push_back("INTEGER");
    string op_a = arop.back();
    if (op_a.at(0) == '[' ) {
        irtmp.push_back("=[] " + new_tmpvar + ", " + op_a.substr(3, op_a.length()-3));
    } else {
        irtmp.push_back("= " + new_tmpvar + ", " + arop.back());
    }
    arop.pop_back();
    arop.push_back(new_tmpvar);
    }
    | NUMBERS {
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        stringstream ssm2;
        ssm2 << $1;
        irtmp.push_back("= " + new_tmpvar + ", " + ssm2.str());
        arop.push_back(new_tmpvar);
    }
    | L_PAREN expression R_PAREN
;
term-id: L_PAREN term-expr R_PAREN {
    while (!fparamsq.empty()) { 
        irtmp.push_back("param " + fparamsq.top());
        fparamsq.pop();
    }
    }
| L_PAREN R_PAREN { }
;
term-expr: expression { 
    fparamsq.push(arop.back());
    arop.pop_back();
}
    | expression COMMA term-expr {
        fparamsq.push(arop.back());
        arop.pop_back();
    }
;
var: IDENTS {
    string var = "_" +* ($1);
    if (!sym_table(var)) {
        exit(0);
    }
    arop.push_back(var);
    }
    | IDENTS L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
        string op_a = arop.back();
        arop.pop_back();
        string var = "_" +* ($1);
        if (!arr_table(var)) {
            exit(0);
        }
        arop.push_back("[] " + var + ", " + op_a);
    }
;
type1: IDENTS ASSIGN expression {
    string var = "_" +* ($1);
    if (!sym_table(var)) {
        exit(0);
    }
    irtmp.push_back("= " + var + ", " + arop.back());
    arop.pop_back();
}
    | IDENTS L_SQUARE_BRACKET expression R_SQUARE_BRACKET ASSIGN expression {
        string var = "_" +* ($1);
        if (!arr_table(var)) {
            exit(0);
        }
        string arr-res-expr = arop.back();
        arop.pop_back();
        string arr-expr = arop.back();
        arop.pop_back();
        irtmp.push_back("[]= _" +* ($1) + ", " + arr-expr + ", " + arr-res-expr);
    }
;
type2: if-expr statements ENDIF {
    irtm.push_back(": " + ifstr.back().at(1));
    ifstr.pop_back();
}
    | elseif statements ENDIF {
        irtmp.push_back(": " + ifstr.back().at(2));
        ifstr.pop_back();
    }
;
type3:  while-expr statements ENDLOOP {
    irtmp.push_back(":= " + loopstr.back().at(0));
    irtmp.push_back(": " + loopstr.back().at(2));
    loopstr.pop_back();
}
;
type4:  do-expr WHILE bool-expr {
    irtmp.push_back("?:= " + loopstr.back().at(0) + ", " + arop.back());
    arop.pop_back();
    loopstr.pop_back();
}
;
type5: READ IDENTS read-mult {
    string var = "_" +* ($2);
    if (!sym_table(var)) {
        exit(0);
    }
    irtmp.push_back(".< _" +* ($2));
    while(!rseqq.empty()) {
        irtmp.push_back(rseqq.top());
        rseqq.pop();
    }
}
    | READ IDENTS L_SQUARE_BRACKET expression R_SQUARE_BRACKET read-mult {
        string var = "_" +* ($2);
        if (!arr_table(var)) {
            exit(0);
        }
        ssm.str("");
        ssm.clear();
        ssm << tmpvar;
        tmpvar++;
        string new_tmpvar = 't' + ssm.str();
        symtbl.push_back(new_tmpvar);
        symtyp.push_back("INTEGER");
        irtmp.push_back(".< " + new_tmpvar);
        irtmp.push_back("[]= _" +* ($2) ", " + arop.back() + ", " + new_tmpvar);
        arop.pop_back();
        while(!rseqq.empty()) {
            irtmp.push_back(rseqq.top());
            rseqq.pop();
        }
    }
;
type6:  WRITE postf type9 {
    while(!arop.empty()) {
        string s3 = arop.front();
        arop.erase(arop.begin());
        irtmp.push_back(".> " + s3)
    }
    arop.clear();
    }
;
type7: CONTINUE {
    if (!loopstr.empty()) {
        if(loopstr.back().at(0).at(0) == 'd') {
            irtmp.push_back(":= " + loopstr.back().at(1));
        } else {
            irtmp.push_back(":= " + loopstr.back().at(0));
        }
    }
}
;
type8:  RETURN expression {
    irtmp.push_back("ret " + arop.back());
    arop.pop_back();
}
;
type9: 
    | COMMA postf type9
;
type6: WRITE postf type9 {
    while(!arop.empty()) {
        string s1 = arop.front();
        arop.erase(arop.begin());
        irtmp.push_back(".> " + s1);
    }
    arop.clear();
}
;
type7: CONTINUE {
    if (!loopstr.empty()) {
        if (loopstr.back().at(0).at(0) == 'd') {
            irtmp.push_back(":= " + loopstr.back().at(1));
        } else {
            irtmp.push_back(":= " + loopstr.back().at(0));
        }
    }
}
;
type8: RETURN expression {
    irtmp.push_back("ret " + arop.back());
    arop.pop_back();
}
;
%%
void yyerror(char* msg){
   printf("error: %s found \'%s\' was found at line #d, column #d\n", msg, yytext, num_lines, num_column);
 }

// void yyerror(char *msg) {
//   return yyerror(string(s));
// }

bool feu_table(string){
  extern int num_column, num_lines;
  for (unsigned int i = 0; i < feutbl.size(); i++) {
    if (feutbl.at(i) == var) {
      return true;
    }
  }
  cerr << "semantic error";
  return false;
}

bool arr_table(string){
  extern int num_lines, num_column;
  for (unsigned int i = 0; i < symtbl.size(); i++) {
    if (symtbl.at(i) == var) {
      if (symtyp.at(i) == "INTEGER" ) {
        // @TODO: print out error message for datatype, too lazy to add this because it's cosmetic rn
        return false;
      } // inner if
      else {
        return true; // check passed go on
      }
    } // outer iff
  } //for
  // @TODO: print out error for undeclared variable of length substring
  return false; 
}

bool sym_table(string){
  extern int num_column, num_lines;
  for (unsigned int i = 0; i < symtbl.size(); i++) {
    if(symtbl.at(i) == var) {
      if (symtyp.at(i) == "INTEGER" ) {
        return true;
      } // inner if
      else {
        // @TODO: print error for incompatible datatype, return substring/length of var
        return false; 
      }
    } // outer iff
  } // end for
  // @TODO: semantic error message
  return false;
}