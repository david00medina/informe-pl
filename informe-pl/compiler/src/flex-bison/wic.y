%{

    /* Declaraciones */

    #include <math.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <iostream>

    #include "../utils/termcolor.hpp"
    #include "../symbol-table/SymbolTable.hpp"
    #include "../ast/AbstractSyntaxTree.hpp"
    #include "../ast/nodes/operator-nodes/ASTArithmeticNode.hpp"
    #include "../code-generator/CodeGenerator.hpp"

    int yylex(void);
    void yyerror(char const *);

    extern int level;
    extern int yylineno;

    wic::GSymbolTable* gst;
    wic::SSymbolTable* sst;
    wic::LSymbolTable* lst;

    wic::AbstractSyntaxTree* ast;
    wic::CodeGenerator* cg;

%}

/* Definición de tipo de valores */
%define api.value.type { void * }

/* Declaración de tokens */

/* Tokens para las palabras reservadas */
%token NEW CONTINUE BREAK RETURN FUN GLOBAL STATIC

/* Tokens de valores de datos */
%token INT_VAL REAL_VAL BOOL_VAL CHAR_VAL STRING_VAL


/* Tokens de tipo de dato */
%token INT_TYPE REAL_TYPE BOOL_TYPE CHAR_TYPE VOID

/* Token de asignación */
%token ASSIGN

/* Tokens de los operadores aritméticos */
%token SUM SUBSTRACT PRODUCT DIVIDE MODULUS POWER RADICAL INCREMENT DECREMENT

/* Tokens de los operadores lógicos */
%token AND OR NOT EQUALS NOT_EQUALS GREATER GREATER_EQUALS LESS LESS_EQUALS

/* Tokens de los operadores bit a bit */
%token AND_BIT OR_BIT XOR_BIT LEFT_SHIFT RIGHT_SHIFT

/* Tokens de los operadores de arrays */
%token UNION DIFFERENCE INTERSECTION

/* Tokens para estructuras de control y bucles */
%token IF_CLAUSE FOR_WHILE_CLAUSE HEADER_END ELSE_IF_FOR_WHILE_CLAUSE

/* Tokens delimitadores */
%token SQUARE_BRACKET_OPEN SQUARE_BRACKET_CLOSE CURLY_BRACKET_OPEN CURLY_BRACKET_CLOSE
%token ELEM_SEPARATOR PARETHESES_OPEN PARETHESES_CLOSE
%token END_OF_INSTR OPEN_CONTEXT_TAG CLOSE_CONTEXT_TAG CHAR_QUOTE STRING_QUOTE

/* Token identificador */
%token ID

/* Tipos de reglas  */

/* Asociatividad y precedencia de los operadores  */
%right ASSIGN NOT
%left UNION DIFFERENCE INTERSECTION
%left LESS LESS_EQUALS GREATER GREATER_EQUALS EQUALS NOT_EQUALS AND OR
%left AND_BIT OR_BIT XOR_BIT LEFT_SHIFT RIGHT_SHIFT
%left SUM SUBSTRACT
%left PRODUCT DIVIDE MODULUS
%left RADICAL
%right POWER
%nonassoc INCREMENT DECREMENT

%start input

%%

/* Definición de gramáticas */

input: instr END_OF_INSTR input
    | END_OF_INSTR input
    | OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG input
    | /* empty */

data_init: GLOBAL data_type			  {
						    wic::entry_data* entry_d = reinterpret_cast<wic::entry_data *>($2);
						    entry_d->var.global = true;
						    entry_d->var.stat = false;
						    entry_d->var.local = false;
						    $$ = entry_d;
						  }
    | STATIC data_type				  {
						    wic::entry_data* entry_d = reinterpret_cast<wic::entry_data *>($2);
						    entry_d->var.global = false;
						    entry_d->var.stat = true;
						    entry_d->var.local = false;
						    $$ = entry_d;
    						  }
    | data_type					  {
    						    wic::entry_data* entry_d = reinterpret_cast<wic::entry_data *>($1);
    						    entry_d->var.global = false;
    						    entry_d->var.stat = false;
    						    entry_d->var.local = true;
    						    $$ = entry_d;
     						  }
    | GLOBAL array_init
    | STATIC array_init
    | array_init

array_init: data_type SQUARE_BRACKET_OPEN INT_VAL SQUARE_BRACKET_CLOSE
    | data_type SQUARE_BRACKET_OPEN SQUARE_BRACKET_CLOSE

data_type: INT_TYPE				  {
						    wic::entry_data* entry_d = new wic::entry_data();
						    entry_d->var.type = wic::INT;
						    entry_d->var.size = 4;
						    $$ = entry_d;
						  }
    | REAL_TYPE					  {
						    wic::entry_data* entry_d = new wic::entry_data();
						    entry_d->var.type = wic::REAL;
						    entry_d->var.size = 4;
						    $$ = entry_d;
						  }
    | BOOL_TYPE 				  {
						    wic::entry_data* entry_d = new wic::entry_data();
						    entry_d->var.type = wic::BOOL;
						    entry_d->var.size = 1;
						    $$ = entry_d;
						  }
    | CHAR_TYPE                                   {
    						    wic::entry_data* entry_d = new wic::entry_data();
    						    entry_d->var.type = wic::CHAR;
    						    entry_d->var.size = 1;
    						    $$ = entry_d;
    						  }
    | VOID					  {
    						    wic::entry_data* entry_d = new wic::entry_data();
						    entry_d->var.type = wic::VOID;
						    entry_d->var.size = 4;
						    $$ = entry_d;
    						  }

instr: data_init ID                               {
						    $$ = ast->tree_build($1, $2);
						  }
    | data_init ID ASSIGN expr                    {
    						    wic::ASTNode* id = ast->tree_build($1, $2);

    						    wic::ASTNode* expr = reinterpret_cast<wic::ASTNode *>($4);
    						    wic::ASTAssignNode* assign = new wic::ASTAssignNode(id->get_data_type(), id, expr);

    						    $$ = ast->tree_build(assign);
    						    ast->print();
    						    std::cout << std::endl;
    						  }
    | ID array_access                             { printf("Término (VectorVal)");}
    | ID ASSIGN expr                              {
    						    wic::ASTIDNode* id = reinterpret_cast<wic::ASTIDNode *>($1);

    						    if (!id->is_registered()) {
    						    	std::cout << termcolor::red << termcolor::bold
    						    	<< "[!] Error: " << termcolor::reset << "\'" << id->get_id()
    						    	<< "\' was not declared in this scope"
    						    	<< std::endl;
    						    	exit(-1);
    						    }

    						    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($3);
    						    wic::ASTAssignNode* assign = new wic::ASTAssignNode(id->get_data_type(), id, term);

    						    ast->tree_build(assign);
    						    $$ = assign;
    						    lst->show(id->get_id());
    						  }
    | ID array_access ASSIGN expr
    | if_instr
    | for_instr
    | while_instr
    | expr                                        {
    						    ast->tree_build(reinterpret_cast<wic::ASTNode *>($1));
                                                    ast->print();
                                                    std::cout << std::endl;
                                                    //$$ = ast->get_root();
                                                  }
    | fun_init
    | fun_call

params: params ELEM_SEPARATOR data_type ID
    | data_type ID

args: args ELEM_SEPARATOR expr
    | expr

fun_init: FUN data_type ID PARETHESES_OPEN params PARETHESES_CLOSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
     {
        // TODO: Pendiente
        // wic::ASTLeafNode* node = reinterpret_cast<wic::ASTIDNode *>($3);
        // printf("Función (nombre=%s)\n", node->get_id());
     }
    | FUN data_type ID PARETHESES_OPEN params PARETHESES_CLOSE END_OF_INSTR

fun_call: ID PARETHESES_OPEN args PARETHESES_CLOSE END_OF_INSTR

while_instr: expr FOR_WHILE_CLAUSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
      while_middle_blocks
      while_end_block

while_middle_blocks: while_middle_blocks
      ELSE_IF_FOR_WHILE_CLAUSE expr FOR_WHILE_CLAUSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

while_end_block: ELSE_IF_FOR_WHILE_CLAUSE FOR_WHILE_CLAUSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

for_instr: expr FOR_WHILE_CLAUSE expr HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
      for_middle_blocks
      for_end_block

for_middle_blocks: for_middle_blocks
      ELSE_IF_FOR_WHILE_CLAUSE expr FOR_WHILE_CLAUSE expr HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

for_end_block: ELSE_IF_FOR_WHILE_CLAUSE FOR_WHILE_CLAUSE HEADER_END END_OF_INSTR
     OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

if_instr: expr IF_CLAUSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
      if_middle_blocks
      if_end_block

if_middle_blocks: if_middle_blocks
      ELSE_IF_FOR_WHILE_CLAUSE expr IF_CLAUSE HEADER_END END_OF_INSTR
      OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

if_end_block: ELSE_IF_FOR_WHILE_CLAUSE IF_CLAUSE HEADER_END END_OF_INSTR
    OPEN_CONTEXT_TAG input CLOSE_CONTEXT_TAG
    | /* empty */

array_access: SQUARE_BRACKET_OPEN INT_VAL SQUARE_BRACKET_CLOSE

expr: ID                                          {
						    wic::ASTIDNode* id = reinterpret_cast<wic::ASTIDNode *>($1);
						    std::cout << "Factor : ID (name=" << id->get_id() << ")" << std::endl;

						    if (!id->is_registered()) {
						  	std::cout << termcolor::red << termcolor::bold
						  	<< "[!] Error: " << termcolor::reset << "\'" << id->get_id()
						  	<< "\' was not declared in this scope"
						  	<< std::endl;
						  	exit(-1);
						    }
						    $$ = id;
						  }
    | expr SUM term                               {
                                                    wic::ASTNode* expr = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTSumNode* sum = new wic::ASTSumNode(expr, term);
						    sum->to_code(cg);
                                                    $$ = ast->tree_build(sum);
                                                  }
    | expr SUBSTRACT term                         {
                                                    wic::ASTNode* expr = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTSubNode* sub = new wic::ASTSubNode(expr, term);

                                                    $$ = ast->tree_build(sub);
                                                  }
    | INCREMENT ID
    | ID INCREMENT
    | DECREMENT ID
    | ID DECREMENT
    | expr LESS term
    | expr LESS_EQUALS term
    | expr GREATER term
    | expr GREATER_EQUALS term
    | expr EQUALS term
    | expr NOT_EQUALS term
    | expr AND term
    | expr OR term
    | NOT term
    | expr AND_BIT term
    | expr OR_BIT term
    | expr XOR_BIT term
    | expr LEFT_SHIFT term
    | expr RIGHT_SHIFT term
    | expr UNION term
    | expr DIFFERENCE term
    | expr INTERSECTION term
    | term
    | data_vector

term: term PRODUCT power                          {
                                                    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* power = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTProdNode* prod = new wic::ASTProdNode(term, power);

                                                    $$ = ast->tree_build(prod);
                                                  }
    | term DIVIDE power                           {
                                                    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* power = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTDivNode* div = new wic::ASTDivNode(term, power);

                                                    $$ = ast->tree_build(div);
                                                  }
    | term MODULUS power                          {
                                                    wic::ASTNode* term = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* power = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTModNode* mod = new wic::ASTModNode(term, power);

                                                    $$ = ast->tree_build(mod);
                                                  }
    | power

power: power RADICAL factor                       {
                                                    wic::ASTNode* power = reinterpret_cast<wic::ASTNode *>($1);
                                                    wic::ASTNode* factor = reinterpret_cast<wic::ASTNode *>($3);

                                                    wic::ASTRadicalNode* radical = new wic::ASTRadicalNode(power, factor);

                                                    $$ = ast->tree_build(radical);
                                                  }
    | power POWER factor
    | factor

factor: PARETHESES_OPEN expr PARETHESES_CLOSE
    | data_value

data_value: INT_VAL                               {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($1);
                                                    std::cout << "Factor : INT(value=" << node->get_data_value().int_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | SUBSTRACT INT_VAL                           {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($2);
                                                    int val = -node->get_data_value().int_val;
                                                    node->set_data_value((void*)&val);
                                                    std::cout << "Factor: NEG_INT(value=" << node->get_data_value().int_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | REAL_VAL                                    {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($1);
                                                    std::cout << "Factor : REAL(value=" << node->get_data_value().real_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | SUBSTRACT REAL_VAL                          {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($2);
                                                    float val = -node->get_data_value().real_val;
                                                    node->set_data_value((void*)&val);
                                                    std::cout << "Factor: NEG_REAL(value=" << node->get_data_value().real_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | BOOL_VAL                                    {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($1);
                                                    std::cout << "Factor : BOOL(value=" << node->get_data_value().bool_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | CHAR_QUOTE CHAR_VAL CHAR_QUOTE              {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($2);
                                                    std::cout << "Factor : CHAR(value=" << node->get_data_value().char_val << ",ascii="
                                                    << (int)node->get_data_value().char_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }
    | STRING_QUOTE STRING_VAL STRING_QUOTE        {
                                                    wic::ASTLeafNode* node = reinterpret_cast<wic::ASTLeafNode *>($2);
                                                    std::cout << "Factor : STRING(value=" << node->get_data_value().str_val << ")" << std::endl;
                                                    $$ = reinterpret_cast<void *>(node);
                                                  }

data_vector: CURLY_BRACKET_OPEN args CURLY_BRACKET_CLOSE

%%