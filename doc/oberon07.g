// ANTLR v3 grammar
grammar oberon07;

// LL(1) with few ambiguities resolved with the help of the symbol table
options {k = 1;}

module : 'MODULE' IDENT ';' (importList)?
         declarationSequence ('BEGIN' statementSequence)? 'END' IDENT '.' ;
importList : 'IMPORT'  import_ (',' import_)* ';';
import_ : IDENT (':=' IDENT)? ;
qualident : (IDENT '.')? IDENT;
identdef : IDENT ('*')?;
constDeclaration : identdef '=' constExpression;
constExpression : expression;
typeDeclaration : identdef '=' type;
type : qualident | arrayType | recordType | pointerType | procedureType;
arrayType : 'ARRAY' length (',' length)* 'OF' type;
length : constExpression;
recordType : 'RECORD' ('(' baseType ')')? (fieldListSequence)? 'END';
baseType : qualident;
fieldListSequence : fieldList (';' fieldList)*;
fieldList : identList ':' type;
identList : identdef (',' identdef)*;
pointerType : 'POINTER' 'TO' type;
procedureType : 'PROCEDURE' (formalParameters)?;
variableDeclaration : identList ':' type;
expression : simpleExpression (relation simpleExpression)?;
relation : '=' | '#' | '<' | '<=' | '>' | '>=' | 'IN' | 'IS';
simpleExpression : ('+' | '-')? term (addOperator term)*;
addOperator : '+' | '-' | 'OR';
term : factor (mulOperator factor)*;
mulOperator : '*' | '/' | 'DIV' | 'MOD' | '&';
factor : number | STRING | 'NIL' | 'TRUE' | 'FALSE' | set |
         designator (actualParameters)? | '(' expression ')' | '~' factor;
designator : qualident (selector)*;
selector : '.' IDENT | '[' expList ']' | '^' | '(' qualident ')';
set : '{' (element (',' element)*)?'}';
element : expression ('..' expression)?;
expList : expression (',' expression)*;
actualParameters : '(' (expList)? ')' ;
statement : (assignment | procedureCall | ifStatement | caseStatement |
            whileStatement | repeatStatement | forStatement)?;
assignment : designator ':=' expression;
procedureCall : designator (actualParameters)?;
statementSequence : statement (';' statement)*;
ifStatement : 'IF' expression 'THEN' statementSequence
              ('ELSIF' expression 'THEN' statementSequence)*
              ('ELSE' statementSequence)? 'END';
caseStatement : 'CASE' expression 'OF' case ('|' case)* 'END';
case : (caseLabelList ':' statementSequence)?;
caseLabelList : labelRange (',' labelRange)*;
labelRange : label ('..' label)?;
label : INTEGER | STRING | qualident;
whileStatement : 'WHILE' expression 'DO' statementSequence
                 ('ELSIF' expression 'DO' statementSequence)* 'END';
repeatStatement : 'REPEAT' statementSequence 'UNTIL' expression;
forStatement : 'FOR' IDENT ':=' expression 'TO' expression
               ('BY' constExpression)? 'DO' statementSequence 'END';
procedureDeclaration : procedureHeading ';' procedureBody IDENT;
procedureHeading : 'PROCEDURE' identdef (formalParameters)?;
procedureBody : declarationSequence ('BEGIN' statementSequence)?
               ('RETURN 'expression)? 'END';
declarationSequence : ('CONST' (constDeclaration ';')*)?
                      ('TYPE' (typeDeclaration ';')*)?
                      ('VAR' (variableDeclaration)* ';')?
                      (procedureDeclaration ';')*;
formalParameters : '(' (fpsection (';' fpsection)*)? ')' (':' qualident)?;
fpsection : ('VAR')? IDENT (',' IDENT)* ':' formalType;
formalType : ('ARRAY' 'OF')* qualident;

number : INTEGER | REAL;

INTEGER  : DIGIT (DIGIT)* | DIGIT (HEX_DIGIT)* 'H';

fragment
STR :  '"' ( ~('"') )* '"' ;

fragment
DIGIT : ('0'..'9') ;

fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
REAL : DIGIT (DIGIT)* '.' (DIGIT)* (SCALE_FACTOR)?;

fragment
SCALE_FACTOR : 'E' ('+' | '-')? DIGIT (DIGIT)*;

STRING : STR | DIGIT (HEX_DIGIT)* 'X';

IDENT  :  ('a'..'z'|'A'..'Z') ('a'..'z'|'A'..'Z'|'0'..'9')* ;

COMMENT :   '(*' ( options {greedy=false;} : . )* '*)' {$channel=HIDDEN;} ;

WS  :  (' ' | '\t' | '\r' | '\n') {$channel=HIDDEN;} ;
