defmodule BashInterpreter.Parser do
  @moduledoc """
  Parser for bash-like syntax.
  Converts tokens into an Abstract Syntax Tree (AST).
  """

  alias BashInterpreter.AST
  alias BashInterpreter.Lexer

  @doc """
  Parses a string of bash commands into an AST.
  
  ## Examples
  
      iex> result = BashInterpreter.Parser.parse("echo hello")
      iex> is_struct(result, BashInterpreter.AST.Script)
      true
      iex> length(result.commands)
      1
      iex> command = hd(result.commands)
      iex> command.name
      "echo"
      iex> command.args
      ["hello"]
      iex> command.redirects
      []
      
      iex> result = BashInterpreter.Parser.parse("if test -f file.txt; then echo found; else echo not found; fi")
      iex> is_struct(result, BashInterpreter.AST.Script)
      true
  """
  def parse(input, _opts \\ []) when is_binary(input) do
    tokens = Lexer.tokenize(input)
    parse_tokens(tokens)
  end

  @doc """
  Parses a list of tokens into an AST.
  """
  def parse_tokens(tokens) do
    {commands, _remaining} = parse_commands(tokens, [])
    
    %AST.Script{commands: commands}
  end

  # Parse a sequence of commands separated by semicolons
  defp parse_commands(tokens, commands \\ [])
  
  # Base case: no more tokens
  defp parse_commands([], commands), do: {Enum.reverse(commands), []}
  
  # Handle if statement
  defp parse_commands([{:command, "if"} | rest], commands) do
    {conditional, remaining} = parse_conditional(rest)
    parse_commands(remaining, [conditional | commands])
  end
  
  # Handle for loop
  defp parse_commands([{:command, "for"} | rest], commands) do
    {loop, remaining} = parse_for_loop(rest)
    parse_commands(remaining, [loop | commands])
  end
  
  # Handle while loop
  defp parse_commands([{:command, "while"} | rest], commands) do
    {loop, remaining} = parse_while_loop(rest)
    parse_commands(remaining, [loop | commands])
  end
  
  # Handle command followed by semicolon
  defp parse_commands(tokens, commands) do
    {command, remaining} = parse_command_or_pipeline(tokens)
    
    case remaining do
      [{:semicolon, _} | rest] -> parse_commands(rest, [command | commands])
      [] -> {Enum.reverse([command | commands]), []}
      _ -> parse_commands(remaining, [command | commands])
    end
  end
  
  # Parse a command or pipeline
  defp parse_command_or_pipeline(tokens) do
    {command, remaining} = parse_simple_command(tokens)
    
    case remaining do
      [{:pipe, _} | rest] ->
        parse_pipeline([command], rest)
      _ ->
        {command, remaining}
    end
  end
  
  # Parse a pipeline of commands
  defp parse_pipeline(commands, tokens) do
    {command, remaining} = parse_simple_command(tokens)
    commands = commands ++ [command]
    
    case remaining do
      [{:pipe, _} | rest] ->
        parse_pipeline(commands, rest)
      _ ->
        pipeline = %AST.Pipeline{commands: commands}
        {pipeline, remaining}
    end
  end
  
  # Parse a simple command with arguments and redirections
  defp parse_simple_command(tokens) do
    case tokens do
      [{:command, name} | rest] ->
        {args, redirects, remaining} = parse_args_and_redirects(rest, [], [])
        
        command = %AST.Command{name: name, args: args, redirects: redirects}
        {command, remaining}
        
      _ ->
        {%AST.Command{name: "", args: [], redirects: []}, tokens}
    end
  end

  # Parse arguments and redirections for a command
  defp parse_args_and_redirects(tokens, args, redirects)
  
  # Base case: no more tokens
  defp parse_args_and_redirects([], args, redirects), do: {Enum.reverse(args), Enum.reverse(redirects), []}
  
  # Stop at semicolon, pipe, or control structure keywords
  defp parse_args_and_redirects([{:semicolon, _} | _] = tokens, args, redirects), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:pipe, _} | _] = tokens, args, redirects), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:command, word} | _] = tokens, args, redirects) when word in ["then", "else", "fi", "do", "done"], do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  
  # Handle output redirection
  defp parse_args_and_redirects([{:redirect_output, _}, {:string, target} | rest], args, redirects) do
    redirect = %AST.Redirect{type: :output, target: target}
    parse_args_and_redirects(rest, args, [redirect | redirects])
  end
  
  # Handle append redirection
  defp parse_args_and_redirects([{:redirect_append, _}, {:string, target} | rest], args, redirects) do
    redirect = %AST.Redirect{type: :append, target: target}
    parse_args_and_redirects(rest, args, [redirect | redirects])
  end
  
  # Handle input redirection
  defp parse_args_and_redirects([{:redirect_input, _}, {:string, target} | rest], args, redirects) do
    redirect = %AST.Redirect{type: :input, target: target}
    parse_args_and_redirects(rest, args, [redirect | redirects])
  end
  
  # Handle variable assignment (e.g., count=$((count + 1)))
  defp parse_args_and_redirects([{:string, name}, {:variable, value} | rest], args, redirects) do
    if String.contains?(name, "=") do
      # This is a variable assignment
      [var_name, _] = String.split(name, "=", parts: 2)
      assignment = %AST.Assignment{name: var_name, value: value}
      {Enum.reverse(args), Enum.reverse(redirects), [{:assignment, assignment} | rest]}
    else
      # Regular argument
      parse_args_and_redirects(rest, [value, name | args], redirects)
    end
  end
  
  # Handle command substitution
  defp parse_args_and_redirects([{:string, value} | rest], args, redirects) do
    if String.starts_with?(value, "$(") && String.ends_with?(value, ")") do
      # This is a command substitution
      cmd_str = String.slice(value, 2..-2)
      {cmd_tokens, _} = tokenize_and_parse(cmd_str)
      parse_args_and_redirects(rest, [cmd_tokens | args], redirects)
    else
      # Regular string argument
      parse_args_and_redirects(rest, [value | args], redirects)
    end
  end
  
  # Handle arguments (strings, options, variables)
  defp parse_args_and_redirects([{type, value} | rest], args, redirects) when type in [:string, :option, :variable] do
    parse_args_and_redirects(rest, [value | args], redirects)
  end
  
  # Skip other tokens
  defp parse_args_and_redirects([_ | rest], args, redirects) do
    parse_args_and_redirects(rest, args, redirects)
  end
  
  # Helper function to tokenize and parse a string
  defp tokenize_and_parse(input) do
    tokens = BashInterpreter.Lexer.tokenize(input)
    parse_command_or_pipeline(tokens)
  end
  
  # Parse conditional (if/then/else)
  defp parse_conditional(tokens) do
    # Extract condition (everything until 'then')
    {condition_tokens, rest} = extract_until(tokens, "then")
    {condition, _} = parse_command_or_pipeline(condition_tokens)
    
    # Skip the 'then' token
    rest = case rest do
      [{:command, "then"} | rest_tokens] -> rest_tokens
      _ -> rest
    end
    
    # Extract then branch (everything until 'else' or 'fi')
    {then_tokens, rest} = extract_until(rest, ["else", "fi"])
    {then_commands, _} = parse_commands(then_tokens, [])
    
    # Use the actual parsed then commands
    then_commands = if then_commands == [] do
      # If no commands were parsed, provide a default empty command
      [%AST.Command{name: "", args: [], redirects: []}]
    else
      then_commands
    end
    
    then_branch = %AST.Script{commands: then_commands}
    
    # Check if we have an else branch
    case rest do
      [{:command, "else"} | else_rest] ->
        {else_tokens, fi_rest} = extract_until(else_rest, "fi")
        {else_commands, _} = parse_commands(else_tokens, [])
        
        # Use the actual parsed else commands
        else_commands = if else_commands == [] do
          # If no commands were parsed, provide a default empty command
          [%AST.Command{name: "", args: [], redirects: []}]
        else
          else_commands
        end
        
        else_branch = %AST.Script{commands: else_commands}
        
        # Skip the 'fi' token
        rest = case fi_rest do
          [{:command, "fi"} | rest_tokens] -> rest_tokens
          _ -> fi_rest
        end
        
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}
        {conditional, rest}
        
      [{:command, "fi"} | rest] ->
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil}
        {conditional, rest}
        
      _ ->
        # Handle malformed conditionals
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil}
        {conditional, rest}
    end
  end
  
  # Parse for loop
  defp parse_for_loop(tokens) do
    case tokens do
      [{:string, variable}, {:command, "in"} | rest] ->
        # Extract items (everything until 'do')
        {items_tokens, do_rest} = extract_until(rest, "do")
        items = Enum.map(items_tokens, fn
          {:string, item} -> item
          {:variable, item} -> item
          {:command, item} -> item
          _ -> ""
        end)
        |> Enum.filter(fn item -> item != "" end)
        
        # Skip the 'do' token
        rest = case do_rest do
          [{:command, "do"} | rest_tokens] -> rest_tokens
          _ -> do_rest
        end
        
        # Extract body (everything until 'done')
        {body_tokens, done_rest} = extract_until(rest, "done")
        {body_commands, _} = parse_commands(body_tokens, [])
        
        # Use the actual parsed body commands
        body_commands = if body_commands == [] do
          # If no commands were parsed, provide a default empty command
          [%AST.Command{name: "", args: [], redirects: []}]
        else
          body_commands
        end
        body = %AST.Script{commands: body_commands}
        
        # Skip the 'done' token
        rest = case done_rest do
          [{:command, "done"} | rest_tokens] -> rest_tokens
          _ -> done_rest
        end
        
        condition = %{variable: variable, items: items}
        loop = %AST.Loop{type: :for, condition: condition, body: body}
        {loop, rest}
    end
  end
  
  # Parse while loop
  defp parse_while_loop(tokens) do
    # Extract condition (everything until 'do')
    {condition_tokens, do_rest} = extract_until(tokens, "do")
    {condition, _} = parse_command_or_pipeline(condition_tokens)
    
    # Skip the 'do' token
    rest = case do_rest do
      [{:command, "do"} | rest_tokens] -> rest_tokens
      _ -> do_rest
    end
    
    # Check for redirections at the end of the body
    {body_tokens, redirects, done_rest} = extract_body_with_redirects(rest, "done")
    {body_commands, _} = parse_commands(body_tokens, [])
    
    # Add redirections to the condition if present
    condition = if redirects != [] do
      %{condition | redirects: condition.redirects ++ redirects}
    else
      condition
    end
    
    body = %AST.Script{commands: body_commands}
    
    # Skip the 'done' token
    rest = case done_rest do
      [{:command, "done"} | rest_tokens] -> rest_tokens
      _ -> done_rest
    end
    
    loop = %AST.Loop{type: :while, condition: condition, body: body}
    {loop, rest}
  end
  
  # Helper function to extract body with redirections
  defp extract_body_with_redirects(tokens, end_keyword) do
    # First, find the 'done' token
    {body_tokens, rest} = extract_until(tokens, end_keyword)
    
    # Check if there are redirections after the body but before 'done'
    case rest do
      [{:command, ^end_keyword}, {:redirect_input, _}, {:string, target} | rest_tokens] ->
        redirect = %AST.Redirect{type: :input, target: target}
        {body_tokens, [redirect], [{:command, end_keyword} | rest_tokens]}
        
      _ ->
        {body_tokens, [], rest}
    end
  end
  
  # Helper function to extract tokens until a specific keyword
  defp extract_until(tokens, keywords_or_keyword)
  
  defp extract_until(tokens, keywords) when is_list(keywords) do
    extract_until_helper(tokens, [], keywords)
  end
  
  defp extract_until(tokens, keyword) when is_binary(keyword) do
    extract_until_helper(tokens, [], [keyword])
  end
  
  defp extract_until_helper([], acc, _keywords), do: {Enum.reverse(acc), []}
  
  defp extract_until_helper([{:command, word} | rest] = tokens, acc, keywords) do
    if word in keywords do
      {Enum.reverse(acc), tokens}
    else
      extract_until_helper(rest, [{:command, word} | acc], keywords)
    end
  end
  
  defp extract_until_helper([token | rest], acc, keywords) do
    extract_until_helper(rest, [token | acc], keywords)
  end
end