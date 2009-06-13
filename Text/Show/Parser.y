{
-- We use these options because Happy generates code with a lot of warnings.
{-# OPTIONS_GHC -w #-}
module Text.Show.Parser (parseValue) where

import Text.Show.Value
import Language.Haskell.Lexer
}

%token

        '='             { (Reservedop, (_,"=")) }
        '('             { (Special, (_,"(")) }
        ')'             { (Special, (_,")")) }
        '{'             { (Special, (_,"{")) }
        '}'             { (Special, (_,"}")) }
        '['             { (Special, (_,"[")) }
        ']'             { (Special, (_,"]")) }
        ','             { (Special, (_,",")) }

        INT             { (IntLit,   (_,$$)) }
        FLOAT           { (FloatLit, (_,$$)) } 
        STRING          { (StringLit, (_,$$)) }
        CHAR            { (CharLit,  (_,$$)) }

        VARID           { (Varid,    (_,$$)) }
        QVARID          { (Qvarid,    (_,$$)) }
        CONID           { (Conid,    (_,$$)) }
        QCONID          { (Qconid,   (_,$$)) }
        CONSYM          { (Consym,   (_,$$)) }
        QCONSYM         { (Qconsym,  (_,$$)) } 


%monad { Maybe } { (>>=) } { return }
%name parseValue value 
%tokentype { PosToken }


%%

value                        :: { Value }
  : con list1(avalue)           { Con $1 $2 }
  | avalue                      { $1 }

avalue                       :: { Value }
  : '(' value ')'               { $2 }
  | '[' sep(value,',') ']'      { List $2 }
  | '(' tuple ')'               { Tuple $2 }
  | con '{' sep(field,',') '}'  { Rec $1 $3 }
  | con                         { Con $1 [] }
  | INT                         { Other $1 }
  | FLOAT                       { Other $1 }
  | STRING                      { Other $1 }
  | CHAR                        { Other $1 }

con                          :: { String }
  : CONID                       { $1 }
  | QCONID                      { $1 }
  -- to support things like "fromList x"
  | VARID                       { $1 }
  | QVARID                      { $1 }

field                        :: { (Name,Value) }
  : VARID '=' value             { ($1,$3) }

tuple                        :: { [Value] }
  :                             { [] }
  | value ',' sep1(value,',')   { $1 : $3 }


-- Common Rule Patterns --------------------------------------------------------

sep1(p,q)       : p list(snd(q,p))    { $1 : $2 }
sep(p,q)        : sep1(p,q)           { $1 }
                |                     { [] }

snd(p,q)        : p q                 { $2 }

list1(p)        : rev_list1(p)        { reverse $1 }
list(p)         : list1(p)            { $1 }
                |                     { [] }

rev_list1(p)    : p                   { [$1] }
                | rev_list1(p) p      { $2 : $1 }




{
happyError :: [PosToken] -> Maybe a
happyError ((_,(p,_)) : _) = Nothing -- error ("Parser error at: " ++ show p)
happyError []              = Nothing -- error ("Parser error at EOF")
}