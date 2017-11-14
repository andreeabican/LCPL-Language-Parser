%code requires {
    #include <iostream>
    #include <string>
    #include <vector>
    #include <ASTNodes.h>
    #include <ASTSerialization.h>
}

%code {
    
    extern FILE *yyin;
    
    lcpl::Program *gLcplProgram;
    std::string gInputFileName;
    
    int yylex();
    void yyerror(const char *error);
}

%locations

%union {
    std::string *stringValue;
    int intValue;
    
    lcpl::Class *lcplClass;
    std::vector<lcpl::Class *> *lcplClasses;
    
    lcpl::Expression *expression;
    std::vector<lcpl::Expression *> *expressions;
    
    lcpl::Feature *feature;
    std::vector<lcpl::Feature *> *features;
    
    lcpl::LocalDefinition *localDefinition;
    lcpl::Assignment *assignment;
    
    lcpl::FormalParam *formal;
    std::vector<lcpl::FormalParam *> *formals;
    
    lcpl::IfStatement *ifStatement;
    lcpl::WhileStatement *whileStatement;
    lcpl::Dispatch *dispatch;
    lcpl::StaticDispatch *staticDispatch;
    lcpl::Block *block;
}

%start lcpl_program

%token KW_STATIC_DISPATCH
%token KW_CONS
%token KW_CLASS KW_END KW_VAR KW_RETURN KW_INHERITS KW_NEW KW_LOCAL KW_NULL
%token KW_IF KW_THEN KW_ELSE KW_WHILE KW_LOOP

%token ADD SUB MUL DIV
%token LESS_THAN GREATER_THAN EQUAL EQUAL_WITH GREATER_THAN_EQUAL LESS_THAN_EQUAL NOT
/* TODO 1: nice if you will add them as tokens, if so, add the parsers in lex file (lcpl.l) */
%token <stringValue> STRING_CONSTANT IDENTIFIER
%token <intValue> INTEGER_CONSTANT

%type <expression> expression conditional_expression string
%type <expression> relational_expression additive_expression multiplicative_expression
%type <expression> unary_expression basic_expression
%type <formal> formal
%type <formals> formals
%type <block> block
%type <feature> method attribute
%type <features> features attributes attribute_definitions
%type <lcplClass> lcpl_class
%type <lcplClasses> lcpl_classes
%type <ifStatement> if_statement
%type <whileStatement> while_statement
%type <dispatch> dispatch
%type <staticDispatch> static_dispatch
%type <assignment> assignment_expression
%type <expressions> expressions local_attribute_definitions local_attributes
%type <localDefinition> local_attribute

%%
lcpl_program : lcpl_classes {
    gLcplProgram = new lcpl::Program(@1.first_line, *$1);
}
;

lcpl_classes : lcpl_class {
    $$ = new std::vector<lcpl::Class*>();
    $$->push_back($1);
}
| lcpl_classes lcpl_class {
    $$ = $1;
    $$->push_back($2);
}
;

lcpl_class : KW_CLASS IDENTIFIER KW_END ';' {
        $$ = new lcpl::Class(@1.first_line, *$2, "");
    }
    | KW_CLASS IDENTIFIER KW_INHERITS IDENTIFIER KW_END ';' {
        $$ = new lcpl::Class(@1.first_line, *$2, std::string(*$4));
    }
    | KW_CLASS IDENTIFIER features KW_END ';' {
        $$ = new lcpl::Class(@1.first_line, *$2, "", *$3);
    }
    | KW_CLASS IDENTIFIER KW_INHERITS IDENTIFIER features KW_END ';' {
        $$ = new lcpl::Class(@1.first_line, *$2, std::string(*$4), *$5);
    }
;

features : method {
        $$ = new std::vector<lcpl::Feature*>();
        $$->push_back($1);
    }
    | features method {
        $1->push_back($2);
        $$ = $1;
    }
    | attributes
    | features attributes {
        $1->insert($1->end(), $2->begin(), $2->end());
        $$ = $1;
    }
    ;
attributes : KW_VAR attribute_definitions KW_END ';' {
        $$ = $2;
    }
    ;

attribute_definitions : attribute ';' {
        $$ = new std::vector<lcpl::Feature*>();
        $$->push_back($1);
    }
    | attribute_definitions attribute ';' {
        $$ = $1;
        $$->push_back($2);
    }
    ;

attribute : IDENTIFIER IDENTIFIER {
        $$ = new lcpl::Attribute(@1.first_line, *$2, *$1);
    }
    | IDENTIFIER IDENTIFIER EQUAL expression {
        $$ = new lcpl::Attribute(@1.first_line, *$2, *$1, lcpl::ExpressionPtr($4));
    }
    ;
method : IDENTIFIER formals ':' KW_END ';' {
        $$ = new lcpl::Method(@1.first_line, *$1, std::string("Void"), nullptr, *$2);
    }
    | IDENTIFIER formals KW_RETURN IDENTIFIER ':' KW_END ';' {
         $$ = new lcpl::Method(@1.first_line, *$1,  std::string(*$4), nullptr, *$2);
    }
    | IDENTIFIER formals ':' block KW_END ';' {
        $$ = new lcpl::Method(@1.first_line, *$1, std::string("Void"), lcpl::ExpressionPtr($4), *$2);
    }
    | IDENTIFIER formals KW_RETURN IDENTIFIER ':' block KW_END ';' {
        $$ = new lcpl::Method(@1.first_line, *$1,  std::string(*$4), lcpl::ExpressionPtr($6), *$2);
    }
    ;

formals : %empty {
        $$ = new std::vector<lcpl::FormalParam*>();
    }
    | formal {
        $$ = new std::vector<lcpl::FormalParam*>();
        $$->push_back($1);
    }
    | formals ',' formal {
        $1->push_back($3);
        $$ = $1;
    }
;

formal : IDENTIFIER IDENTIFIER {
        $$ = new lcpl::FormalParam(@1.first_line, *$2, *$1);
    }
    ;

block : expression ';' {
        $$ = new lcpl::Block(@1.first_line);
        $$->addExpression(lcpl::ExpressionPtr($1));
    }
    | block expression ';'  {
        $$ = $1;
        $$->addExpression(lcpl::ExpressionPtr($2));
    }
    | block local_attributes ';' {
        for(std::vector<int>::size_type i = 0; i != $2->size(); i++) {
            $1->addExpression(lcpl::ExpressionPtr((*$2)[i]));
        }
        $$ = $1;
    }
    | local_attributes ';' {
        $$ = new lcpl::Block(@1.first_line);
        for(std::vector<int>::size_type i = 0; i != $1->size(); i++) {
            $$->addExpression(lcpl::ExpressionPtr((*$1)[i]));
        }
    }
    ;

local_attributes: KW_LOCAL local_attribute_definitions KW_END  {
        $$ = $2;
    }
    ;

local_attribute_definitions: local_attribute ';' {
        $$ = new std::vector<lcpl::Expression*>();
        $$->push_back($1);
    }
    | local_attribute_definitions local_attribute ';' {
        $$ = $1;
        $$->push_back($2);
    }
    ;

local_attribute: IDENTIFIER IDENTIFIER {
        $$ = new lcpl::LocalDefinition(@1.first_line, *$2, *$1);
    }
    | IDENTIFIER IDENTIFIER EQUAL expression {
        $$ = new lcpl::LocalDefinition(@1.first_line, *$2, *$1, lcpl::ExpressionPtr($4));
    }
    ;

expression : assignment_expression
    ;

assignment_expression: IDENTIFIER EQUAL assignment_expression {
        $$ = new lcpl::Assignment(@1.first_line, std::string(*$1), lcpl::ExpressionPtr($3));
    }
    | conditional_expression;

conditional_expression : relational_expression
    ;

relational_expression : additive_expression
    | additive_expression LESS_THAN additive_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::LessThan,
            lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    | additive_expression GREATER_THAN additive_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::LessThan,
            lcpl::ExpressionPtr($3), lcpl::ExpressionPtr($1));
    }
    | additive_expression EQUAL_WITH additive_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::Equal,
            lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    | additive_expression LESS_THAN_EQUAL additive_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::LessThanEqual,
            lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    | additive_expression GREATER_THAN_EQUAL additive_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::LessThanEqual,
            lcpl::ExpressionPtr($3), lcpl::ExpressionPtr($1));

    }
    ;

additive_expression : multiplicative_expression
    | additive_expression ADD multiplicative_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::Add,
        lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    | additive_expression SUB multiplicative_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::Sub,
        lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    ;

multiplicative_expression : unary_expression
    | multiplicative_expression MUL unary_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::Mul,
            lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    | multiplicative_expression DIV unary_expression {
        $$ = new lcpl::BinaryOperator(@1.first_line, lcpl::BinaryOperator::BinOpKind::Div,
            lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3));
    }
    ;

unary_expression : basic_expression
    | NOT basic_expression {
        $$ = new lcpl::UnaryOperator(@1.first_line, lcpl::UnaryOperator::UnaryOpKind::Not,
            lcpl::ExpressionPtr($2));
    }
    | SUB basic_expression {
        $$ = new lcpl::UnaryOperator(@1.first_line, lcpl::UnaryOperator::UnaryOpKind::Minus, lcpl::ExpressionPtr($2));
    }
;

basic_expression : INTEGER_CONSTANT {
        $$ = new lcpl::IntConstant(@1.first_line, $1);
    }
    | string
    | KW_NEW IDENTIFIER {
        $$ = new lcpl::NewObject(@1.first_line, std::string(*$2));
    }
    | KW_NULL {
        $$ = new lcpl::NullConstant(@1.first_line);
    }
    | '{' IDENTIFIER expression '}' {
        $$ = new lcpl::Cast(@1.first_line, std::string(*$2), lcpl::ExpressionPtr($3));
    }
    | basic_expression '['expression ',' expression ']' {
        $$ = new lcpl::Substring(@1.first_line, lcpl::ExpressionPtr($1), lcpl::ExpressionPtr($3), lcpl::ExpressionPtr($5));
    }
    | '(' expression ')' {
        $$ = $2;
    }
    | while_statement
    | if_statement
    | dispatch
    | static_dispatch
;

string: STRING_CONSTANT {
        $$ = new lcpl::StringConstant(@1.first_line, *$1);
    }
    | IDENTIFIER {
        $$ = new lcpl::Symbol(@1.first_line, *$1);
    }
    ;

if_statement: KW_IF conditional_expression KW_THEN KW_ELSE block KW_END {
    $$ = new lcpl::IfStatement(@1.first_line, lcpl::ExpressionPtr($2), lcpl::ExpressionPtr(new lcpl::Block(@1.first_line)), lcpl::ExpressionPtr($5));
    }
    | KW_IF conditional_expression KW_THEN block KW_ELSE block KW_END {
        $$ = new lcpl::IfStatement(@1.first_line, lcpl::ExpressionPtr($2),
        lcpl::ExpressionPtr($4), lcpl::ExpressionPtr($6));
    }
    | KW_IF conditional_expression KW_THEN block KW_END {
        $$ = new lcpl::IfStatement(@1.first_line, lcpl::ExpressionPtr($2),
        lcpl::ExpressionPtr($4));
    };

while_statement: KW_WHILE conditional_expression KW_LOOP block KW_END {
        $$ = new lcpl::WhileStatement(@1.first_line, lcpl::ExpressionPtr($2), lcpl::ExpressionPtr($4));
    }
    ;

dispatch: '[' IDENTIFIER ']' {
        $$ = new lcpl::Dispatch(@1.first_line, std::string(*$2), nullptr);
    }
    | '[' IDENTIFIER expressions ']' {
        $$ = new lcpl::Dispatch(@1.first_line, std::string(*$2), nullptr, *$3);
    }
    | '[' expression '.' IDENTIFIER expressions ']' {
        $$ = new lcpl::Dispatch(@1.first_line, std::string(*$4), lcpl::ExpressionPtr($2), *$5);
    }
    | '[' expression '.' IDENTIFIER ']' {
        $$ = new lcpl::Dispatch(@1.first_line, std::string(*$4), lcpl::ExpressionPtr($2));
    }
    ;

static_dispatch: '[' expression KW_STATIC_DISPATCH IDENTIFIER '.' IDENTIFIER expressions ']' {
        $$ = new lcpl::StaticDispatch(@1.first_line, lcpl::ExpressionPtr($2), std::string(*$4), std::string(*$6), *$7);
    }
    | '[' expression KW_STATIC_DISPATCH IDENTIFIER '.' IDENTIFIER ']' {
        $$ = new lcpl::StaticDispatch(@1.first_line, lcpl::ExpressionPtr($2), std::string(*$4), std::string(*$6));
    }
    ;

expressions: expression {
        $$ = new std::vector<lcpl::Expression *>();
        $$->push_back($1);
    }
    | expressions ',' expression  {
        $$ = $1;
        $$->push_back($3);
    }
    ;


%%

int main(int argc, char** argv) {
    if(argc != 2) {
        std::cerr << "Usage: ./lcpl-parser <file>" << std::endl;
        return 1;
    }
    
    gInputFileName = std::string(argv[1]);
    yyin = fopen(argv[1], "r");
    if(!yyin) {
        std::cerr << "Error opening file: " << argv[1] << std::endl;
        return 1;
    }
    
    std::cout << "This is the mighty LCPL Parser at work!" << std::endl;
    yyparse();
    std::cout << "Finished parsing!" << std::endl;
    
    lcpl::ASTSerializer serializer(gInputFileName + ".ast");
    serializer.visit(gLcplProgram);
    std::cout << "Finished writing AST file!" << std::endl;
    
    return 0;
}

void yyerror(const char *error) {
    std::cout << gInputFileName << ":" << yylloc.first_line << ":" << yylloc.first_column << "-"
    << yylloc.last_column << " " << error << std::endl;
    exit(1);
}

