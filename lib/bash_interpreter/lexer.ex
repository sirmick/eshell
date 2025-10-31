defmodule BashInterpreter.Lexer do
  @moduledoc """
  Lexer for bash-like syntax.
  Converts input text into a stream of tokens.
  """

  # Keywords used in bash syntax
  @keywords ["if", "then", "else", "elif", "fi", "for", "in", "do", "done", "while", "until"]

  @doc """
  Tokenizes the input string into a list of tokens.
  
  ## Examples
  
      iex> BashInterpreter.Lexer.tokenize("echo hello")
      [{:command, "echo"}, {:string, "hello"}]
  """
  def tokenize(input, _opts \\ []) when is_binary(input) do
    # Trim the input for tokenization
    trimmed_input = String.trim(input)
    
    # Tokenize the input
    tokens = tokenize_input(trimmed_input, [])
    
    # Return tokens
    tokens
  end

  # Base case: no more input to tokenize
  defp tokenize_input("", tokens), do: Enum.reverse(tokens)

  # Skip whitespace
  defp tokenize_input(<<" ", rest::binary>>, tokens) do
    tokenize_input(rest, tokens)
  end
  
  defp tokenize_input(<<"\t", rest::binary>>, tokens) do
    tokenize_input(rest, tokens)
  end
  
  defp tokenize_input(<<"\n", rest::binary>>, tokens) do
    tokenize_input(rest, tokens)
  end

  # Handle pipe operator
  defp tokenize_input(<<"|", rest::binary>>, tokens) do
    token = {:pipe, "|"}
    tokenize_input(rest, [token | tokens])
  end

  # Handle semicolon
  defp tokenize_input(<<";", rest::binary>>, tokens) do
    token = {:semicolon, ";"}
    tokenize_input(rest, [token | tokens])
  end

  # Handle redirections
  defp tokenize_input(<<">>", rest::binary>>, tokens) do
    token = {:redirect_append, ">>"}
    tokenize_input(rest, [token | tokens])
  end
  
  defp tokenize_input(<<">", rest::binary>>, tokens) do
    token = {:redirect_output, ">"}
    tokenize_input(rest, [token | tokens])
  end
  
  defp tokenize_input(<<"<", rest::binary>>, tokens) do
    token = {:redirect_input, "<"}
    tokenize_input(rest, [token | tokens])
  end

  # Handle double-quoted strings
  defp tokenize_input(<<"\"", rest::binary>>, tokens) do
    {string, remaining} = extract_quoted_string(rest, "\"", "")
    token = {:string, string}
    tokenize_input(remaining, [token | tokens])
  end

  # Handle single-quoted strings
  defp tokenize_input(<<"'", rest::binary>>, tokens) do
    {string, remaining} = extract_quoted_string(rest, "'", "")
    token = {:string, string}
    tokenize_input(remaining, [token | tokens])
  end

  # Handle variables (starting with $)
  defp tokenize_input(<<"$", rest::binary>>, tokens) do
    {var_name, remaining} = extract_word(rest, "")
    token = {:variable, "$" <> var_name}
    tokenize_input(remaining, [token | tokens])
  end

  # Handle options (starting with -)
  defp tokenize_input(<<"-", rest::binary>>, tokens) do
    {option_rest, remaining} = extract_word(rest, "-")
    token = {:option, option_rest}
    tokenize_input(remaining, [token | tokens])
  end

  # Handle words (commands, arguments, etc.)
  defp tokenize_input(input, tokens) do
    {word, remaining} = extract_word(input, "")
    token_type = determine_token_type(word, tokens)
    token = {token_type, word}
    tokenize_input(remaining, [token | tokens])
  end

  # Helper function to extract a quoted string
  defp extract_quoted_string(<<"\\", c, rest::binary>>, quote_char, acc) when c == quote_char do
    extract_quoted_string(rest, quote_char, acc <> <<c>>)
  end
  
  defp extract_quoted_string(<<quote_char, rest::binary>>, quote_char, acc) do
    {acc, rest}
  end
  
  defp extract_quoted_string(<<char, rest::binary>>, quote_char, acc) do
    extract_quoted_string(rest, quote_char, acc <> <<char>>)
  end
  
  defp extract_quoted_string("", _quote_char, acc) do
    # Handle unclosed quotes by returning what we have
    {acc, ""}
  end

  # Helper function to extract a word (command, argument, etc.)
  defp extract_word(input, prefix \\ "")
  
  defp extract_word("", acc), do: {acc, ""}
  
  defp extract_word(<<char, rest::binary>>, acc) when char in [?\s, ?\t, ?\n, ?|, ?;, ?>, ?<] do
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
      word in ["test", "grep", "read", "cat", "echo", "ls", "wc"] -> :command
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