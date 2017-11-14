%{
    
    #include "lcpl.tab.h"
    #include <string>
    
    #define TABSIZE 4
    
    void countColumns();
    static void yyunput (int, register char *) __attribute__ ((unused));
    
    #define YY_USER_ACTION countColumns();
%}

%option yylineno

%%

"class" { return KW_CLASS; }
"inherits" { return KW_INHERITS; }
"end" { return KW_END; }
"local" { return KW_LOCAL; }
"var" { return KW_VAR; }
"if" { return KW_IF; }
"then" { return KW_THEN; }
"else" { return KW_ELSE; }
"new" { return KW_NEW; }
"->" { return KW_RETURN; }
"null" { return KW_NULL; }
"while" { return KW_WHILE; }
"loop" { return KW_LOOP; }
"::" { return KW_STATIC_DISPATCH; }

"+" { return ADD; }
"-" { return SUB; }
"*" { return MUL; }
"/" { return DIV; }
"=" { return EQUAL; }
"<" { return LESS_THAN; }
"<=" { return LESS_THAN_EQUAL; }
">=" { return GREATER_THAN_EQUAL; }
">" { return GREATER_THAN; }
"==" { return EQUAL_WITH; }
"!" { return NOT; }

"#"[^\r\n]*    { }
[ \t\r\n] { }

[a-zA-Z]([0-9a-zA-Z_])* {
    yylval.stringValue = new std::string(yytext);
    return IDENTIFIER;
}
L?\"(\\.|[^\\"])*\" {
yylval.stringValue = new std::string((new std::string(yytext))->substr(1, (new std::string(yytext))->length()-2));
    return STRING_CONSTANT;
}

[0]|([1-9][0-9]*) {
    yylval.intValue = atoi(yytext);
    return INTEGER_CONSTANT;
}

. {
    return yytext[0];
}

%%

int yywrap(void) {
    return 1;
}

void countColumns() {
    yylloc.first_line = yylloc.last_line = yylineno;
    yylloc.first_column = yylloc.last_column;
    
    if(yytext[0] == '\n' && !yytext[1]) {
        yylloc.first_column = yylloc.last_column = 1;
    }
    else if(yytext[0] == '\t' && !yytext[1]) {
        int difference = (yylloc.last_column == TABSIZE ? 0 : TABSIZE);
        yylloc.last_column += difference - (yylloc.last_column % TABSIZE) + 1;
    }
    else {
        yylloc.last_column += yyleng;
    }
}
