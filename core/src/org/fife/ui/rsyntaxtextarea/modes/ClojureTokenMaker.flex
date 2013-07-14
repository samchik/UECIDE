/*
 * 12/23/2010
 *
 * ClojureTokenMaker.java - Scanner for Clojure.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for the Clojure programming language.<p>
 *
 * This was graciously donated by the folks at the
 * <a href="http://pacific.mpi-cbg.de/wiki/index.php/Fiji">Fiji</a> project.
 * Its original location was
 * <a href="http://pacific.mpi-cbg.de/cgi-bin/gitweb.cgi?p=fiji.git;a=tree;f=src-plugins/Script_Editor/fiji/scripting;hb=935d85d9d88dd780c6d5f2765937ddc18b5008ca">here</a>.
 * <p>
 * 
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated ClojureTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 *
 */
%%

%public
%class ClojureTokenMaker
%extends AbstractJFlexTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public ClojureTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 * @see #addToken(int, int, int)
	 */
	private void addHyperlinkToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, true);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 * @see #addHyperlinkToken(int, int, int)
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, false);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 * @param hyperlink Whether this token is a hyperlink.
	 */
	public void addToken(char[] array, int start, int end, int tokenType,
						int startOffset, boolean hyperlink) {
		super.addToken(array, start,end, tokenType, startOffset, hyperlink);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns the text to place at the beginning and end of a
	 * line to "comment" it in a this programming language.
	 *
	 * @return The start and end strings to add to a line to "comment"
	 *         it out.
	 */
	public String[] getLineCommentStartAndEnd() {
		return new String[] { ";", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;
		switch (initialTokenType) {
			/*case Token.COMMENT_MULTILINE:
				state = MLC;
				start = text.offset;
				break;
			case Token.COMMENT_DOCUMENTATION:
				state = DOCCOMMENT;
				start = text.offset;
				break;*/
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = STRING;
				start = text.offset;
				break;
			default:
				state = Token.NULL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new Token();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 * @exception   IOException  if any I/O-Error occurs.
	 */
	private boolean zzRefill() throws java.io.IOException {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream
	 */
	public final void yyreset(java.io.Reader reader) throws java.io.IOException {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}


LineCommentBegin						= (";")
Keyword                                 =  ([:][a-zA-Z?!\-+*/][a-zA-Z0-9?!\-+*/]*)
NonzeroDigit						    = [1-9]
Digit							        = ("0"|{NonzeroDigit})
HexDigit							    = ({Digit}|[A-Fa-f])
OctalDigit						        = ([0-7])
EscapedSourceCharacter				    = ("u"{HexDigit}{HexDigit}{HexDigit}{HexDigit})
Escape							        = ("\\"(([btnfr\"'\\])|([0123]{OctalDigit}?{OctalDigit}?)|({OctalDigit}{OctalDigit}?)|{EscapedSourceCharacter}))
AnyCharacterButDoubleQuoteOrBackSlash	= ([^\\\"\n])
UnclosedStringLiteral					= ([\"]([\\].|[^\\\"])*[^\"]?)
ErrorStringLiteral						= ({UnclosedStringLiteral}[\"])
StringLiteral                           = ([\"])
CharLiteral                        		= ("\\."|"\\space"|"\\tab"|"\\newline")
AnyCharacter                            = ([.]*)
Separator								= ([\(\)\{\}\[\]])
NonSeparator						= ([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\'])

BooleanLiteral						=("true"|"false")

LineTerminator				= (\n)
WhiteSpace				= ([ \t\f])

IntegerHelper1				= (({NonzeroDigit}{Digit}*)|"0")
IntegerHelper2				= ("0"(([xX]{HexDigit}+)|({OctalDigit}*)))
IntegerLiteral				= ({IntegerHelper1}[lL]?)
HexLiteral				= ({IntegerHelper2}[lL]?)
FloatHelper1				= ([fFdD]?)
FloatHelper2				= ([eE][+-]?{Digit}+{FloatHelper1})
FloatLiteral1				= ({Digit}+"."({FloatHelper1}|{FloatHelper2}|{Digit}+({FloatHelper1}|{FloatHelper2})))
FloatLiteral2				= ("."{Digit}+({FloatHelper1}|{FloatHelper2}))
FloatLiteral3				= ({Digit}+{FloatHelper2})
FloatLiteral				= ({FloatLiteral1}|{FloatLiteral2}|{FloatLiteral3}|({Digit}+[fFdD]))
ErrorNumberFormat			= (({IntegerLiteral}|{HexLiteral}|{FloatLiteral}){NonSeparator}+)


Nil                         = ("nil")
Quote                       = (\('\|`\))
Unquote                     = (\(\~@\|\~\))
DispatchStart               = ("#^"|"#^{")
Dispatch 					= ({DispatchStart}[^\s\t\n;\"}]*([ \t\n;\"]|"}"))
VarQuote                    = ("#'"[.]*[ \t\n;(\"])
DefName 					= (\s*[a-zA-Z0-9?!\-+*\./<>]*)

NonAssignmentOperator		= ("+"|"-"|"<="|"^"|"<"|"*"|">="|"%"|">"|"/"|"!="|"?"|">>"|"!"|"&"|"=="|":"|">>"|"~"|">>>")
AssignmentOperator			= ("=")
Operator					= ({NonAssignmentOperator}|{AssignmentOperator})

Letter					= [A-Za-z]
LetterOrUnderscore		= ({Letter}|[_])
Digit					= [0-9]
URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ({LetterOrUnderscore}|{Digit}|[\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$]|{Letter}|{Digit})
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)


%state STRING
%state EOL_COMMENT

%%

<YYINITIAL> {

"case" |
"class" |
"cond" |
"condp" |
"def" |
"defmacro" |
"defn" |
"do" |
"fn" |
"for" |
"if" |
"if-let" |
"if-not" |
"instance?" |
"let" |
"loop" |
"monitor-enter" |
"monitor-exit" |
"new" |
"quote" |
"recur" |
"set!" |
"this" |
"throw" |
"try-finally" |
"var" |
"when" |
"when-first" |
"when-let" |
"when-not"        { addToken(Token.RESERVED_WORD); }

"*warn-on-reflection*" |
"*1" |
"*2" |
"*3" |
"*agent*" |
"*allow-unresolved-args*" |
"*assert*" |
"*clojure-version*" |
"*command-line-args*" |
"*compile-files*" |
"*compile-path*" |
"*e" |
"*err*" |
"*file*" |
"*flush-on-newline*" |
"*fn-loader*" |
"*in*" |
"*math-context*" |
"*ns*" |
"*out*" |
"*print-dup*" |
"*print-length*" |
"*print-level*" |
"*print-meta*" |
"*print-readably*" |
"*read-eval*" |
"*source-path*" |
"*unchecked-math*" |
"*use-context-classloader*"		{ addToken(Token.VARIABLE); }

"*current-namespace*" |
"*in*" |
"*out*" |
"*print-meta*"
"->" |
".." |
"agent" |
"agent-errors" |
"agent-of" |
"aget" |
"alter" |
"and" |
"any" |
"appl" |
"apply" |
"array" |
"aset" |
"aset-boolean" |
"aset-byte" |
"aset-double" |
"aset-float" |
"aset-int" |
"aset-long" |
"aset-short" |
"assoc" |
"binding" |
"boolean" |
"byte" |
"char" |
"clear-agent-errors" |
"commute" |
"comp" |
"complement" |
"concat" |
"conj" |
"cons" |
"constantly" |
"count" |
"cycle" |
"dec" |
"defmethod" |
"defmulti" |
"delay" |
"deref" |
"dissoc" |
"doseq" |
"dotimes" |
"doto" |
"double" |
"drop" |
"drop-while" |
"ensure" |
"eql-ref?" |
"eql?" |
"eval" |
"every" |
"ffirst" |
"filter" |
"find" |
"find-var" |
"first" |
"float" |
"fnseq" |
"frest" |
"gensym" |
"get" |
"hash-map" |
"identity" |
"implement" |
"import" |
"in-namespace" |
"inc" |
"int" |
"into" |
"into-array" |
"iterate" |
"key" |
"keys" |
"lazy-cons" |
"list" |
"list*" |
"load-file" |
"locking" |
"long" |
"make-array" |
"make-proxy" |
"map" |
"mapcat" |
"max" |
"memfn" |
"merge" |
"meta" |
"min" |
"name" |
"namespace" |
"neg?" |
"newline" |
"nil?" |
"not" |
"not-any" |
"not-every" |
"nth" |
"or" |
"peek" |
"pmap" |
"pop" |
"pos?" |
"print" |
"prn" |
"quot" |
"range" |
"read" |
"reduce" |
"ref" |
"refer" |
"rem" |
"remove-method" |
"repeat" |
"replicate" |
"rest" |
"reverse" |
"rfirst" |
"rrest" |
"rseq" |
"second" |
"seq" |
"set" |
"short" |
"sorted-map" |
"sorted-map-by" |
"split-at" |
"split-with" |
"str" |
"strcat" |
"sym" |
"sync" |
"take" |
"take-while" |
"time" |
"unimport" |
"unintern" |
"unrefer" |
"val" |
"vals" |
"vector" |
"with-meta" |
"zero?" |
"zipmap"      				{ addToken(Token.FUNCTION); }

{LineTerminator}				{ addNullToken(); return firstToken; }

{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

{CharLiteral}					{ addToken(Token.LITERAL_CHAR); }
{StringLiteral}				{ start = zzMarkedPos-1; yybegin(STRING); }
	//{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	//{ErrorStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); }

{Nil}                           { addToken(Token.DATA_TYPE); }

{BooleanLiteral}				{ addToken(Token.LITERAL_BOOLEAN); }


{Quote}							{ addToken(Token.SEPARATOR); }
{Unquote}						{ addToken(Token.SEPARATOR); }
{VarQuote}						{ addToken(Token.SEPARATOR); }
{Dispatch}						{ addToken(Token.DATA_TYPE); }

{LineCommentBegin}			{ start = zzMarkedPos-1; yybegin(EOL_COMMENT); }

{Separator}					{ addToken(Token.SEPARATOR); }

{Operator}					{ addToken(Token.OPERATOR); }

{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
{HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
{FloatLiteral}					{ addToken(Token.LITERAL_NUMBER_FLOAT); }
{ErrorNumberFormat}				{ addToken(Token.ERROR_NUMBER_FORMAT); }
{Keyword}						{ addToken(Token.PREPROCESSOR); }
{DefName}						{ addToken(Token.IDENTIFIER); }

<<EOF>>						{ addNullToken(); return firstToken; }

.							{ addToken(Token.ERROR_IDENTIFIER); }

}

<STRING> {

	[^\n\"]+				{}
	\n					{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
	"\"\""				{}
	"\""					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.LITERAL_STRING_DOUBLE_QUOTE); }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }

}

<EOL_COMMENT> {
	[^hwf\n]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_EOL); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; }
	[hwf]					{}
	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }

}
