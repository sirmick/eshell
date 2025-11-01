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
    parse_tokens(tokens, input)
  end

  @doc """
  Parses a list of tokens into an AST.
  """
  def parse_tokens(tokens, original_input \\ "") do
    {commands, _remaining} = parse_commands(tokens, [], original_input)
    
    %AST.Script{commands: commands, source_info: original_input}
  end

  # Parse a sequence of commands separated by semicolons
  defp parse_commands(tokens, commands, original_input)
  
  # Base case: no more tokens
  defp parse_commands([], commands, _original_input), do: {Enum.reverse(commands), []}
  
  # Handle if statement
  defp parse_commands([{:command, "if"} | rest], commands, original_input) do
    {conditional, remaining} = parse_conditional(rest, original_input)
    parse_commands(remaining, [conditional | commands], original_input)
  end
  
  # Handle for loop
  defp parse_commands([{:command, "for"} | rest], commands, original_input) do
    {loop, remaining} = parse_for_loop(rest, original_input)
    parse_commands(remaining, [loop | commands], original_input)
  end
  
  # Handle while loop
  defp parse_commands([{:command, "while"} | rest], commands, original_input) do
    {loop, remaining} = parse_while_loop(rest, original_input)
    parse_commands(remaining, [loop | commands], original_input)
  end
  
  # Handle command followed by semicolon
  defp parse_commands(tokens, commands, original_input) do
    {command, remaining} = parse_command_or_pipeline(tokens, original_input)
    
    case remaining do
      [{:semicolon, _} | rest] -> parse_commands(rest, [command | commands], original_input)
      [] -> {Enum.reverse([command | commands]), []}
      _ -> parse_commands(remaining, [command | commands], original_input)
    end
  end
  
  # Parse a command or pipeline
  defp parse_command_or_pipeline(tokens, original_input) do
    {command, remaining} = parse_simple_command(tokens, original_input)
    
    case remaining do
      [{:pipe, _} | rest] ->
        parse_pipeline([command], rest, original_input)
      _ ->
        {command, remaining}
    end
  end
  
  # Parse a pipeline of commands
  defp parse_pipeline(commands, tokens, original_input) do
    {command, remaining} = parse_simple_command(tokens, original_input)
    commands = commands ++ [command]
    
    case remaining do
      [{:pipe, _} | rest] ->
        parse_pipeline(commands, rest, original_input)
      _ ->
        # Extract source info for the entire pipeline
        source_info = extract_source_snippet(original_input, commands)
        pipeline = %AST.Pipeline{commands: commands, source_info: source_info}
        {pipeline, remaining}
    end
  end
  
  # Parse a simple command with arguments and redirections
  defp parse_simple_command(tokens, original_input) do
    case tokens do
      [{:command, name} | rest] ->
        {args, redirects, remaining} = parse_args_and_redirects(rest, [], [], original_input)
        
        # Extract source info for this command
        source_info = extract_command_source(name, args, redirects, original_input)
        command = %AST.Command{name: name, args: args, redirects: redirects, source_info: source_info}
        {command, remaining}
        
      _ ->
        {%AST.Command{name: "", args: [], redirects: [], source_info: ""}, tokens}
    end
  end

  # Parse arguments and redirections for a command
  defp parse_args_and_redirects(tokens, args, redirects, original_input)
  
  # Base case: no more tokens
  defp parse_args_and_redirects([], args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), []}
  
  # Stop at semicolon, pipe, or control structure keywords
  defp parse_args_and_redirects([{:semicolon, _} | _] = tokens, args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:pipe, _} | _] = tokens, args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:command, word} | _] = tokens, args, redirects, _original_input) when word in ["then", "else", "fi", "do", "done"], do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  
  # Handle output redirection
  defp parse_args_and_redirects([{:redirect_output, _}, {:string, target} | rest], args, redirects, original_input) do
    source_info = extract_redirect_source(">", target, original_input)
    redirect = %AST.Redirect{type: :output, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end
  
  # Handle append redirection
  defp parse_args_and_redirects([{:redirect_append, _}, {:string, target} | rest], args, redirects, original_input) do
    source_info = extract_redirect_source(">>", target, original_input)
    redirect = %AST.Redirect{type: :append, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end
  
  # Handle input redirection
  defp parse_args_and_redirects([{:redirect_input, _}, {:string, target} | rest], args, redirects, original_input) do
    source_info = extract_redirect_source("<", target, original_input)
    redirect = %AST.Redirect{type: :input, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end
  
  # Handle variable assignment (e.g., count=$((count + 1)))
  defp parse_args_and_redirects([{:string, name}, {:variable, value} | rest], args, redirects, original_input) do
    if String.contains?(name, "=") do
      # This is a variable assignment
      [var_name, _] = String.split(name, "=", parts: 2)
      source_info = extract_assignment_source(var_name, value, original_input)
      assignment = %AST.Assignment{name: var_name, value: value, source_info: source_info}
      {Enum.reverse(args), Enum.reverse(redirects), [{:assignment, assignment} | rest]}
    else
      # Regular argument
      parse_args_and_redirects(rest, [value, name | args], redirects, original_input)
    end
  end
  
  # Handle command substitution token
  defp parse_args_and_redirects([{:command_substitution, cmd_str} | rest], args, redirects, original_input) do
    # Parse the command inside the substitution
    cmd_ast = BashInterpreter.parse(cmd_str)
    # Use the first command from the AST
    cmd = if length(cmd_ast.commands) > 0 do
      hd(cmd_ast.commands)
    else
      %AST.Command{name: "", args: [], redirects: [], source_info: ""}
    end
    parse_args_and_redirects(rest, [cmd | args], redirects, original_input)
  end

  # Handle string tokens
  defp parse_args_and_redirects([{:string, value} | rest], args, redirects, original_input) do
    # Regular string argument
    parse_args_and_redirects(rest, [value | args], redirects, original_input)
  end
  
  # Handle arguments (strings, options, variables)
  defp parse_args_and_redirects([{type, value} | rest], args, redirects, original_input) when type in [:string, :option, :variable] do
    parse_args_and_redirects(rest, [value | args], redirects, original_input)
  end
  
  # Skip other tokens
  defp parse_args_and_redirects([_ | rest], args, redirects, original_input) do
    parse_args_and_redirects(rest, args, redirects, original_input)
  end
  
  # Helper function to tokenize and parse a string
  defp tokenize_and_parse(input) do
    tokens = BashInterpreter.Lexer.tokenize(input)
    parse_command_or_pipeline(tokens, input)
  end
  
  # Parse conditional (if/then/else)
  defp parse_conditional(tokens, original_input) do
    # Extract condition (everything until 'then')
    {condition_tokens, rest} = extract_until(tokens, "then")
    
    # Parse the condition as a command or pipeline
    {condition, _} = parse_command_or_pipeline(condition_tokens, original_input)
    
    # Skip the 'then' token
    rest = case rest do
      [{:command, "then"} | rest_tokens] -> rest_tokens
      _ -> rest
    end
    
    # Extract then branch (everything until 'else' or 'fi')
    {then_tokens, rest} = extract_until(rest, ["else", "fi"])
    
    # Parse the then branch as a sequence of commands
    # This will correctly handle nested structures
    then_ast = parse_tokens(then_tokens, extract_branch_source(then_tokens, original_input))
    then_branch = then_ast
    
    # Check if we have an else branch
    case rest do
      [{:command, "else"} | else_rest] ->
        {else_tokens, fi_rest} = extract_until(else_rest, "fi")
        
        # Parse the else branch as a sequence of commands
        # This will correctly handle nested structures
        else_ast = parse_tokens(else_tokens, extract_branch_source(else_tokens, original_input))
        else_branch = else_ast
        
        # Skip the 'fi' token
        rest = case fi_rest do
          [{:command, "fi"} | rest_tokens] -> rest_tokens
          _ -> fi_rest
        end
        
        source_info = extract_conditional_source(condition, then_branch, else_branch, original_input)
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch, source_info: source_info}
        {conditional, rest}
        
      [{:command, "fi"} | rest] ->
        source_info = extract_conditional_source(condition, then_branch, nil, original_input)
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil, source_info: source_info}
        {conditional, rest}
        
      _ ->
        # Handle malformed conditionals
        source_info = extract_conditional_source(condition, then_branch, nil, original_input)
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil, source_info: source_info}
        {conditional, rest}
    end
  end
  
  # Parse for loop
  defp parse_for_loop(tokens, original_input) do
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
        
        # Parse the body as a complete script
        # This will correctly handle nested structures
        body_ast = parse_tokens(body_tokens, extract_branch_source(body_tokens, original_input))
        body = body_ast
        
        # Skip the 'done' token
        rest = case done_rest do
          [{:command, "done"} | rest_tokens] -> rest_tokens
          _ -> done_rest
        end
        
        condition = %{variable: variable, items: items}
        source_info = extract_for_loop_source(variable, items, body, original_input)
        loop = %AST.Loop{type: :for, condition: condition, body: body, source_info: source_info}
        {loop, rest}
    end
  end
  
  # Parse while loop
  defp parse_while_loop(tokens, original_input) do
    # Extract condition (everything until 'do')
    {condition_tokens, do_rest} = extract_until(tokens, "do")
    {condition, _} = parse_command_or_pipeline(condition_tokens, original_input)
    
    # Skip the 'do' token
    rest = case do_rest do
      [{:command, "do"} | rest_tokens] -> rest_tokens
      _ -> do_rest
    end
    
    # Check for redirections at the end of the body
    {body_tokens, redirects, done_rest} = extract_body_with_redirects(rest, "done")
    
    # Parse the body as a complete script
    # This will correctly handle nested structures
    body_ast = parse_tokens(body_tokens, extract_branch_source(body_tokens, original_input))
    body = body_ast
    
    # Add redirections to the condition if present
    condition = if redirects != [] do
      %{condition | redirects: condition.redirects ++ redirects}
    else
      condition
    end
    
    # Skip the 'done' token
    rest = case done_rest do
      [{:command, "done"} | rest_tokens] -> rest_tokens
      _ -> done_rest
    end
    
    source_info = extract_while_loop_source(condition, body, original_input)
    loop = %AST.Loop{type: :while, condition: condition, body: body, source_info: source_info}
    {loop, rest}
  end
  
  # Helper function to extract body with redirections
  defp extract_body_with_redirects(tokens, end_keyword) do
    # First, find the 'done' token, respecting nested structures
    {body_tokens, rest} = extract_until(tokens, end_keyword)
    
    # Check if there are redirections after the body but before 'done'
    case rest do
      [{:command, ^end_keyword}, {:redirect_input, _}, {:string, target} | rest_tokens] ->
        redirect = %AST.Redirect{type: :input, target: target, source_info: "< #{target}"}
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
  
  # Helper functions to extract source info (simple implementation)
  
  defp extract_command_source(name, args, _redirects, original_input) do
    # For simplicity, extract the whole line that contains this command
    lines = String.split(original_input, "\n")
    Enum.find(lines, fn line -> String.contains?(line, name) end) || "#{name} #{Enum.join(args, " ")}"
  end
  
  defp extract_source_snippet(original_input, _commands) do
    # For pipelines, return a simplified version or find the pipeline in original text
    String.trim(original_input)
  end
  
  defp extract_redirect_source(operator, target, _original_input) do
    "#{operator} #{target}"
  end
  
  defp extract_assignment_source(name, value, _original_input) do
    "#{name}=#{value}"
  end
  
  defp extract_branch_source(_tokens, original_input) do
    # For branches, return relevant part of original input
    String.trim(original_input)
  end
  
  defp extract_conditional_source(_condition, _then_branch, _else_branch, original_input) do
    # For conditionals, return the original input (simplified)
    String.trim(original_input)
  end
  
  defp extract_for_loop_source(_variable, _items, _body, original_input) do
    # For for loops, return the original input (simplified)
    String.trim(original_input)
  end
  
  defp extract_while_loop_source(_condition, _body, original_input) do
    # For while loops, return the original input (simplified)
    String.trim(original_input)
  end
end