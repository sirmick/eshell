defmodule BashInterpreter.Lexer do
  @moduledoc """
  Lexer for bash-like syntax.
  Converts input text into a stream of tokens.
  """

  # Keywords used in bash syntax
  @keywords ["if", "then", "else", "elif", "fi", "for", "in", "do", "done", "while", "until"]

  # Common commands for special handling
  @common_commands ["test", "grep", "read", "cat", "echo", "ls", "wc"]

  @doc """
  Tokenizes the input string into a list of tokens.
  
  ## Examples
  
      iex> BashInterpreter.Lexer.tokenize("echo hello")
      [{:command, "echo"}, {:string, "hello"}]
  """
  def tokenize(input, _opts \\ []) when is_binary(input) do
    # Trim the input for tokenization
    trimmed_input = String.trim(input)
    
    # Tokenize the input using a state machine approach
    tokenize_with_state(trimmed_input)
  end

  # State machine for tokenization
  defp tokenize_with_state(input) do
    tokenize_with_state(input, [], :normal)
  end

  # Base case: no more input
  defp tokenize_with_state("", tokens, _state), do: Enum.reverse(tokens)

  # Normal state (outside quotes)
  
  # Skip whitespace in normal state
  defp tokenize_with_state(<<" ", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, tokens, :normal)
  end
  
  defp tokenize_with_state(<<"\t", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, tokens, :normal)
  end
  
  defp tokenize_with_state(<<"\n", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, tokens, :normal)
  end

  # Handle pipe operator in normal state
  defp tokenize_with_state(<<"|", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, [{:pipe, "|"} | tokens], :normal)
  end

  # Handle semicolon in normal state
  defp tokenize_with_state(<<";", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, [{:semicolon, ";"} | tokens], :normal)
  end

  # Handle redirections in normal state
  defp tokenize_with_state(<<">>", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, [{:redirect_append, ">>"} | tokens], :normal)
  end
  
  defp tokenize_with_state(<<">", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, [{:redirect_output, ">"} | tokens], :normal)
  end
  
  defp tokenize_with_state(<<"<", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, [{:redirect_input, "<"} | tokens], :normal)
  end

  # Handle command substitution in normal state
  defp tokenize_with_state(<<"$(", rest::binary>>, tokens, :normal) do
    {cmd_content, remaining} = extract_balanced_parens(rest)
    tokenize_with_state(remaining, [{:command_substitution, "$(#{cmd_content})"} | tokens], :normal)
  end

  # Handle double quotes in normal state
  defp tokenize_with_state(<<"\"", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, tokens, {:in_double_quote, ""})
  end

  # Handle single quotes in normal state
  defp tokenize_with_state(<<"'", rest::binary>>, tokens, :normal) do
    tokenize_with_state(rest, tokens, {:in_single_quote, ""})
  end

  # Handle variables in normal state
  defp tokenize_with_state(<<"$", rest::binary>>, tokens, :normal) do
    {var_name, remaining} = extract_word(rest)
    tokenize_with_state(remaining, [{:variable, "$#{var_name}"} | tokens], :normal)
  end

  # Handle options in normal state
  defp tokenize_with_state(<<"-", rest::binary>>, tokens, :normal) do
    {option, remaining} = extract_word(rest)
    tokenize_with_state(remaining, [{:option, "-#{option}"} | tokens], :normal)
  end

  # Handle words in normal state
  defp tokenize_with_state(input, tokens, :normal) do
    {word, remaining} = extract_word(input)
    token_type = determine_token_type(word, tokens)
    tokenize_with_state(remaining, [{token_type, word} | tokens], :normal)
  end

  # Double quote state
  
  # End of double quote
  defp tokenize_with_state(<<"\"", rest::binary>>, tokens, {:in_double_quote, acc}) do
    tokenize_with_state(rest, [{:string, acc} | tokens], :normal)
  end
  
  # Escaped double quote within double quotes
  defp tokenize_with_state(<<"\\\"", rest::binary>>, tokens, {:in_double_quote, acc}) do
    tokenize_with_state(rest, tokens, {:in_double_quote, acc <> "\\\""})
  end
  
  # Other escaped characters within double quotes
  defp tokenize_with_state(<<"\\", c, rest::binary>>, tokens, {:in_double_quote, acc}) do
    tokenize_with_state(rest, tokens, {:in_double_quote, acc <> "\\" <> <<c>>})
  end
  
  # Regular character within double quotes
  defp tokenize_with_state(<<char, rest::binary>>, tokens, {:in_double_quote, acc}) do
    tokenize_with_state(rest, tokens, {:in_double_quote, acc <> <<char>>})
  end
  
  # End of input with unclosed double quote
  defp tokenize_with_state("", tokens, {:in_double_quote, acc}) do
    Enum.reverse([{:string, acc} | tokens])
  end
  
  # Single quote state
  
  # End of single quote
  defp tokenize_with_state(<<"'", rest::binary>>, tokens, {:in_single_quote, acc}) do
    tokenize_with_state(rest, [{:string, acc} | tokens], :normal)
  end
  
  # Regular character within single quotes (no escaping in single quotes)
  defp tokenize_with_state(<<char, rest::binary>>, tokens, {:in_single_quote, acc}) do
    tokenize_with_state(rest, tokens, {:in_single_quote, acc <> <<char>>})
  end
  
  # End of input with unclosed single quote
  defp tokenize_with_state("", tokens, {:in_single_quote, acc}) do
    Enum.reverse([{:string, acc} | tokens])
  end

  # Extract balanced parentheses for command substitution
  defp extract_balanced_parens(input) do
    extract_balanced_parens(input, "", 0)
  end
  
  defp extract_balanced_parens("", acc, _level), do: {acc, ""}
  
  defp extract_balanced_parens(<<")", rest::binary>>, acc, 0), do: {acc, rest}
  
  defp extract_balanced_parens(<<"(", rest::binary>>, acc, level) do
    extract_balanced_parens(rest, acc <> "(", level + 1)
  end
  
  defp extract_balanced_parens(<<")", rest::binary>>, acc, level) do
    extract_balanced_parens(rest, acc <> ")", level - 1)
  end
  
  defp extract_balanced_parens(<<"\"", rest::binary>>, acc, level) do
    {quoted_content, remaining} = extract_quoted_content(rest, "\"")
    extract_balanced_parens(remaining, acc <> "\"" <> quoted_content <> "\"", level)
  end
  
  defp extract_balanced_parens(<<"'", rest::binary>>, acc, level) do
    {quoted_content, remaining} = extract_quoted_content(rest, "'")
    extract_balanced_parens(remaining, acc <> "'" <> quoted_content <> "'", level)
  end
  
  defp extract_balanced_parens(<<char, rest::binary>>, acc, level) do
    extract_balanced_parens(rest, acc <> <<char>>, level)
  end

  # Extract content within quotes
  defp extract_quoted_content(input, quote_char) do
    extract_quoted_content(input, quote_char, "")
  end
  
  defp extract_quoted_content("", _quote_char, acc), do: {acc, ""}
  
  defp extract_quoted_content(<<c::binary-size(1), rest::binary>>, quote_char, acc) when c == quote_char do
    {acc, rest}
  end
  
  defp extract_quoted_content(<<"\\", c::binary-size(1), rest::binary>>, quote_char, acc) when c == quote_char do
    extract_quoted_content(rest, quote_char, acc <> c)
  end
  
  defp extract_quoted_content(<<"\\", c::binary-size(1), rest::binary>>, quote_char, acc) do
    extract_quoted_content(rest, quote_char, acc <> "\\" <> c)
  end
  
  defp extract_quoted_content(<<char::binary-size(1), rest::binary>>, quote_char, acc) do
    extract_quoted_content(rest, quote_char, acc <> char)
  end

  # Extract a word until a delimiter is encountered
  defp extract_word(input) do
    extract_word(input, "")
  end
  
  defp extract_word("", acc), do: {acc, ""}
  
  defp extract_word(<<char, rest::binary>>, acc) when char in [?\s, ?\t, ?\n, ?|, ?;, ?>, ?<, ?", ?'] do
    if acc == "" do
      {<<char>>, rest}
    else
      {acc, <<char>> <> rest}
    end
  end
  
  defp extract_word(<<char, rest::binary>>, acc) do
    extract_word(rest, acc <> <<char>>)
  end

  # Determine if a word is a command, keyword, or string
  defp determine_token_type(word, tokens) do
    cond do
      word in @keywords -> :command
      # Special case for common commands
      word in @common_commands -> :command
      # First token or after pipe/semicolon is a command
      tokens == [] ||
      hd(tokens) in [{:pipe, "|"}, {:semicolon, ";"}, {:command, "then"},
                     {:command, "else"}, {:command, "do"}] -> :command
      # Special case for "in" which is always a command
      word == "in" -> :command
      # Special case for "*.txt" in for loops
      tokens != [] && hd(tokens) == {:command, "in"} -> :string
      true -> :string
    end
  end
end