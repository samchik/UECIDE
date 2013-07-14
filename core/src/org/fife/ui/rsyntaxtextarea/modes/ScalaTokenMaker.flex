/*
 * 8/19/2009
 *
 * ScalaTokenMaker.java - Scanner for the Scala programming language.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for the Scala programming language.<p>
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
 *   <li>The generated ScalaTokenMaker.java</code> file will contain two
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
 * @author Robert Futrell
 * @version 0.5
 *
 */
%%

%public
%class ScalaTokenMaker
%extends AbstractJFlexCTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public ScalaTokenMaker() {
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
		return new String[] { "//", null };
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
		int state = YYINITIAL;
		switch (initialTokenType) {
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = MULTILINE_STRING_DOUBLE;
				break;
			case Token.COMMENT_MULTILINE:
				state = MLC;
				break;
			default:
				state = YYINITIAL;
		}

		s = text;
		start = text.offset;
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
	public final void yyreset(java.io.Reader reader) throws IOException {
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
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}


/***** BEGIN SCALA-SPECIFIC CHANGES *********/
Upper						= ([A-Z\$\_]) /* Plus Unicode category Lu */
Lower						= ([a-z])     /* Plus Unicode category Ll */
Letter						= ({Upper}|{Lower}) /*Plus Unicode categories Lo, Lt, Nl */
Digit						= ([0-9])
OpChar						= ([^A-Z\$\_a-z0-9\(\[\]\)\. \t\f])
Op							= ({OpChar}+)
IdRest						= (({Letter}|{Digit})*([\_]{Op})?)
VarId						= ({Lower}{IdRest})
PlainId						= ({Upper}{IdRest}|{VarId}) /*|{Op})*/
Id							= ({PlainId}) /*({PlainId}|[\']{StringLit}[\'])*/

IntegerLiteral				= ({Digit}+[Ll]?)
HexDigit					= ({Digit}|[A-Fa-f])
HexLiteral					= ("0x"{HexDigit}+)

ExponentPart				= ([Ee][+\-]?{Digit}+)
FloatType					= ([FfDd])
FloatingPointLiteral		= ({Digit}+[\.]{Digit}*{ExponentPart}?{FloatType}? |
							  [\.]{Digit}+{ExponentPart}?{FloatType}? |
							  {Digit}+{ExponentPart}{FloatType}? |
							  {Digit}+{ExponentPart}?{FloatType})

UnclosedCharLiteral			= ([\']([\\].|[^\\\'])*[^\']?)
CharLiteral					= ({UnclosedCharLiteral}[\'])
UnclosedStringLiteral		= ([\"]([\\].|[^\\\"])*[^\"]?)
StringLiteral				= ({UnclosedStringLiteral}[\"])
UnclosedBacktickLiteral		= ([\`][^\`]+)
BacktickLiteral				= ({UnclosedBacktickLiteral}[\`])
/* TODO: Multiline strings */

MLCBegin					= ("/*")
MLCEnd						= ("*/")
LineCommentBegin			= ("//")

/***** END SCALA-SPECIFIC CHANGES *********/

Whitespace				= ([ \t\f]+)
LineTerminator			= ([\n])
Separator				= ([\(\)\{\}\[\]])

URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ({Letter}|[\_]|{Digit}|[\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$]|{Letter}|{Digit})
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)


%state MULTILINE_STRING_DOUBLE
%state MLC
%state EOL_COMMENT

%%

<YYINITIAL> {

	/* Keywords */
	"abstract" |
	"case" |
	"catch" |
	"class" |
	"def" |
	"do" |
	"else" |
	"extends" |
	"false" |
	"final" |
	"finally" |
	"for" |
	"forSome" |
	"if" |
	"implicit" |
	"import" |
	"lazy" |
	"match" |
	"new" |
	"null" |
	"object" |
	"override" |
	"package" |
	"private" |
	"protected" |
	"requires" |
	"return" |
	"sealed" |
	"super" |
	"this" |
	"throw" |
	"trait" |
	"try" |
	"true" |
	"type" |
	"val" |
	"var" |
	"while" |
	"with" |
	"yield" 			{ addToken(Token.RESERVED_WORD); }

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{Id}						{ addToken(Token.IDENTIFIER); }

	{Whitespace}					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	\"\"\"						{ start = zzMarkedPos-3; yybegin(MULTILINE_STRING_DOUBLE); }
	{UnclosedCharLiteral}			{ addToken(Token.ERROR_CHAR); addNullToken(); return firstToken; }
	{CharLiteral}				{ addToken(Token.LITERAL_CHAR); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedBacktickLiteral}		{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{BacktickLiteral}				{ addToken(Token.LITERAL_BACKQUOTE); }

	/* Comment literals. */
	{MLCBegin}					{ start = zzMarkedPos-2; yybegin(MLC); }
	{LineCommentBegin}				{ start = zzMarkedPos-2; yybegin(EOL_COMMENT); }

	{Separator}					{ addToken(Token.SEPARATOR); }

	{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{FloatingPointLiteral}			{ addToken(Token.LITERAL_NUMBER_FLOAT); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters. */
	.							{ addToken(Token.IDENTIFIER); }

}

<MULTILINE_STRING_DOUBLE> {
	[^\"\\\n]*				{}
	\\.?						{ /* Skip escaped chars, handles case: '\"""'. */ }
	\"\"\"					{ addToken(start,zzStartRead+2, Token.LITERAL_STRING_DOUBLE_QUOTE); yybegin(YYINITIAL); }
	\"						{}
	\n |
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
}

<MLC> {
	[^hwf\n\*]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_MULTILINE); start = zzMarkedPos; }
	[hwf]					{}
	{MLCEnd}					{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\*						{}
	\n |
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
}

<EOL_COMMENT> {
	[^hwf\n]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_EOL); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; }
	[hwf]					{}
	\n |
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }
}
