defmodule BashInterpreter.Parser do
  @moduledoc """
  Parser for bash-like syntax.
  Converts tokens into an Abstract Syntax Tree (AST).
  """

  alias BashInterpreter.AST
  alias BashInterpreter.AST.SourceInfo
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

    # Only keep a minimal source_info with the complete text for round-trip walker
    source_info = SourceInfo.new(original_input)
    %AST.Script{commands: commands, source_info: source_info}
  end

  # Parse a sequence of commands separated by semicolons
  defp parse_commands(tokens, commands, original_input)

  # Base case: no more tokens
  defp parse_commands([], commands, _original_input), do: {Enum.reverse(commands), []}

  # Skip empty semicolons and control structure keywords
  defp parse_commands([{:semicolon, _} | rest], commands, original_input) do
    parse_commands(rest, commands, original_input)
  end

  defp parse_commands([{:command, word} | rest], commands, original_input) when word in ["fi", "done", "then", "do", "else"] do
    parse_commands(rest, commands, original_input)
  end

  # Handle control structures generically
  defp parse_commands([{:command, keyword} | rest], commands, original_input) do
    case keyword do
      "if" ->
        {conditional, remaining} = parse_conditional(rest, original_input)
        parse_commands(remaining, [conditional | commands], original_input)

      "for" ->
        {loop, remaining} = parse_for_loop(rest, original_input)
        parse_commands(remaining, [loop | commands], original_input)

      "while" ->
        {loop, remaining} = parse_while_loop(rest, original_input)
        parse_commands(remaining, [loop | commands], original_input)

      _ ->
        # Handle regular commands
        {command, remaining} = parse_command_or_pipeline([{:command, keyword} | rest], original_input)
        parse_commands(remaining, [command | commands], original_input)
    end
  end

  # Handle other token types
  defp parse_commands([token | rest], commands, original_input) do
    {command, remaining} = parse_command_or_pipeline([token | rest], original_input)
    parse_commands(remaining, [command | commands], original_input)
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
        # Create a pipeline AST node with minimal source info
        source_info = SourceInfo.new("")
        pipeline = %AST.Pipeline{commands: commands, source_info: source_info}
        {pipeline, remaining}
    end
  end

  # Parse a simple command with arguments and redirections
  defp parse_simple_command(tokens, original_input) do
    case tokens do
      [{:command, name} | rest] ->
        {args, redirects, remaining} = parse_args_and_redirects(rest, [], [], original_input)

        # Create a command AST node with minimal source info
        source_info = SourceInfo.new("")
        command = %AST.Command{name: name, args: args, redirects: redirects, source_info: source_info}
        {command, remaining}

      [{:string, str} | rest] ->
        # Handle string tokens that might be bracket expressions or other complex conditions
        {args, redirects, remaining} = parse_args_and_redirects(rest, [str], [], original_input)
        source_info = SourceInfo.new("")
        command = %AST.Command{name: "", args: args, redirects: redirects, source_info: source_info}
        {command, remaining}

      _ ->
        source_info = SourceInfo.new("")
        {%AST.Command{name: "", args: [], redirects: [], source_info: source_info}, tokens}
    end
  end

  # Parse arguments and redirections for a command
  defp parse_args_and_redirects(tokens, args, redirects, original_input)

  # Base case: no more tokens
  defp parse_args_and_redirects([], args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), []}

  # Stop at semicolon, pipe, or control structure keywords
  defp parse_args_and_redirects([{:semicolon, _} | _] = tokens, args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:pipe, _} | _] = tokens, args, redirects, _original_input), do: {Enum.reverse(args), Enum.reverse(redirects), tokens}
  defp parse_args_and_redirects([{:command, word} | _] = tokens, args, redirects, _original_input) when word in ["then", "else", "fi", "do", "done", "in"], do: {Enum.reverse(args), Enum.reverse(redirects), tokens}

  # Handle bracket expressions like [ -f file.txt ]
  defp parse_args_and_redirects([{:string, "["} | rest], args, redirects, original_input) do
    # Handle bracket expressions as a single argument
    {bracket_args, remaining} = parse_bracket_expression(rest, ["["], [])
    bracket_expr = Enum.join(bracket_args, " ")
    parse_args_and_redirects(remaining, [bracket_expr | args], redirects, original_input)
  end

  # Handle output redirection
  defp parse_args_and_redirects([{:redirect_output, _}, {:string, target} | rest], args, redirects, original_input) do
    # Create a redirect AST node with minimal source info
    source_info = SourceInfo.new("")
    redirect = %AST.Redirect{type: :output, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end

  # Handle append redirection
  defp parse_args_and_redirects([{:redirect_append, _}, {:string, target} | rest], args, redirects, original_input) do
    # Create a redirect AST node with minimal source info
    source_info = SourceInfo.new("")
    redirect = %AST.Redirect{type: :append, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end

  # Handle input redirection
  defp parse_args_and_redirects([{:redirect_input, _}, {:string, target} | rest], args, redirects, original_input) do
    # Create a redirect AST node with minimal source info
    source_info = SourceInfo.new("")
    redirect = %AST.Redirect{type: :input, target: target, source_info: source_info}
    parse_args_and_redirects(rest, args, [redirect | redirects], original_input)
  end

  # Handle variable assignment (e.g., count=$((count + 1)))
  defp parse_args_and_redirects([{:string, name}, {:variable, value} | rest], args, redirects, original_input) do
    if String.contains?(name, "=") do
      # This is a variable assignment
      [var_name, _] = String.split(name, "=", parts: 2)

      # Create an assignment AST node with minimal source info
      source_info = SourceInfo.new("")
      assignment = %AST.Assignment{name: var_name, value: value, source_info: source_info}
      {Enum.reverse(args), Enum.reverse(redirects), [{:assignment, assignment} | rest]}
    else
      # Regular argument
      parse_args_and_redirects(rest, [value, name | args], redirects, original_input)
    end
  end

  # Handle command substitution token
  defp parse_args_and_redirects([{:command_substitution, cmd_str} | rest], args, redirects, original_input) do
    # Just use the string representation rather than a nested Command struct
    cmd_sub = "$(#{cmd_str})"
    parse_args_and_redirects(rest, [cmd_sub | args], redirects, original_input)
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

  # Helper to parse bracket expressions like [ -f file.txt ]
  defp parse_bracket_expression(tokens, acc, bracket_args) do
    case tokens do
      [{:string, "]"} | rest] ->
        {acc ++ ["]"], rest}

      [{:string, value} | rest] ->
        parse_bracket_expression(rest, acc ++ [value], bracket_args ++ [value])

      [{:command, cmd} | rest] ->
        parse_bracket_expression(rest, acc ++ [cmd], bracket_args ++ [cmd])

      [_ | rest] ->
        parse_bracket_expression(rest, acc, bracket_args)

      [] ->
        {acc, []}
    end
  end

  # Parse conditional (if/then/else)
  defp parse_conditional(tokens, original_input) do
    # Extract condition (everything until 'then')
    {condition_tokens, rest} = extract_until_nested(tokens, ["then"], ["if", "fi", "for", "while", "do", "done"])

    # Build the condition as a single command with all tokens as arguments
    condition = build_condition_command(condition_tokens)

    # Skip the 'then' token
    rest = case rest do
      [{:command, "then"} | rest_tokens] -> rest_tokens
      _ -> rest
    end

    # Extract then branch (everything until 'else' or 'fi')
    {then_tokens, post_then} = extract_until_nested(rest, ["else", "fi"], ["if", "fi", "for", "while", "do", "done"])

    # Check if we have an else branch - restore the else token
    {have_else, rest} = case post_then do
      [{:command, "else"} | _else_rest] ->
        {true, post_then}  # Keep the full post_then without modification
      _ ->
        {false, post_then}
    end

    # Parse the then branch as a sequence of commands
    then_branch = parse_tokens(then_tokens, "")


    # Check if we have an else branch
    case rest do
      [{:command, "else"} | else_rest] when have_else ->
        # Extract tokens for the else branch (everything until 'fi')
        {else_tokens, fi_rest} = extract_until_nested(else_rest, ["fi"], ["if", "fi", "for", "while", "do", "done"])

        # Parse the else branch as a separate script to maintain its command structure
        else_branch = parse_tokens(else_tokens, "")

        # Skip the 'fi' token
        rest = case fi_rest do
          [{:command, "fi"} | rest_tokens] -> rest_tokens
          _ -> fi_rest
        end

        # Create a conditional AST node with minimal source info
        source_info = SourceInfo.new("")
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch, source_info: source_info}
        {conditional, rest}

      [{:command, "fi"} | rest] ->
        # Create a conditional AST node without else branch
        source_info = SourceInfo.new("")
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil, source_info: source_info}
        {conditional, rest}

      _ ->
        # Handle malformed conditionals but attempt to continue parsing
        source_info = SourceInfo.new("")
        conditional = %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: nil, source_info: source_info}
        {conditional, rest}
    end
  end

  # Helper to build a condition command from tokens
  defp build_condition_command(tokens) do
    if Enum.empty?(tokens) do
      source_info = SourceInfo.new("")
      %AST.Command{name: "", args: [], redirects: [], source_info: source_info}
    else
      # Build the complete condition as arguments
      args = Enum.map(tokens, fn
        {:command, cmd} -> cmd
        {:string, str} -> str
        {:option, opt} -> opt
        {:variable, var} -> var
        _ -> ""
      end)
      |> Enum.reject(&(&1 == ""))

      # Handle the args properly - if the first token is already "test", don't duplicate it
      # If it's a bracket expression or other format, handle accordingly
      {name, final_args} = cond do
        # First token is already "test" - use it and remove from args
        List.first(args) == "test" ->
          {"test", Enum.drop(args, 1)}

        # First token is "[" - this is a test expression
        List.first(args) == "[" ->
          {"test", args}

        # Default case - if condition doesn't start with "test", use "test" as command name
        true ->
          {"test", args}
      end

      source_info = SourceInfo.new("")
      %AST.Command{name: name, args: final_args, redirects: [], source_info: source_info}
    end
  end

  # Debug helper to trace conditional parsing issues
  defp extract_until_nested_debug(tokens, end_keywords, nested_keywords, debug_name) do
    result = extract_until_nested(tokens, end_keywords, nested_keywords)
    IO.puts("DEBUG: Processing #{debug_name}")
    IO.puts("  Input tokens: #{inspect(Enum.take(tokens, 10))}...")
    IO.puts("  End keywords: #{inspect(end_keywords)}")
    IO.puts("  Result: #{inspect(result)}")
    result
  end

  # Helper to extract for loop items including command substitutions
  defp extract_for_loop_items(tokens) do
    # Process tokens to extract items, properly handling command substitutions
    Enum.reduce(tokens, [], fn token, acc ->
      item = case token do
        {:string, value} -> value
        {:variable, value} -> value
        {:command, value} when value not in ["in", "do", "done"] -> value
        {:command_substitution, cmd} -> "$(#{cmd})"  # Command substitution
        {:assignment, _} -> "" # Skip assignments
        _ -> ""
      end

      if item != "", do: [item | acc], else: acc
    end)
    |> Enum.reverse()
    |> Enum.filter(fn item -> item != "" end)
  end

  # Parse for loop
  defp parse_for_loop(tokens, original_input) do
    # Check for different for loop patterns
    case tokens do
      # Handle standard "for variable in items" format
      [{:string, variable}, {:command, "in"} | rest] ->
        # Extract items (everything until 'do')
        {items_tokens, do_rest} = extract_until(rest, "do")

        # Handle complex cases like "$(grep "pattern" file.txt)" properly
        items = extract_for_loop_items(items_tokens)

        # Skip the 'do' token
        rest = case do_rest do
          [{:command, "do"} | rest_tokens] -> rest_tokens
          _ -> do_rest
        end

        # Extract body (everything until 'done')
        # Use extract_until_nested to properly handle nested loops and conditionals
        {body_tokens, done_rest} = extract_until_nested(rest, ["done"], ["if", "fi", "for", "while", "do"])

        # Parse the body as a complete script with proper source info
        body = parse_tokens(body_tokens, "")

        # Skip the 'done' token and don't include it in the script
        rest = case done_rest do
          [{:command, "done"} | rest_tokens] -> rest_tokens
          _ -> done_rest
        end

        # Create for loop AST node
        condition = %{variable: variable, items: items}
        source_info = SourceInfo.new("")
        loop = %AST.Loop{type: :for, condition: condition, body: body, source_info: source_info}
        {loop, rest}

      # Handle other formats or error cases
      _ ->
        # Return an empty loop with empty source info
        source_info = SourceInfo.new("")
        loop = %AST.Loop{type: :for, condition: %{variable: "", items: []}, body: %AST.Script{commands: []}, source_info: source_info}
        {loop, tokens}
    end
  end

  # Parse while loop
  defp parse_while_loop(tokens, original_input) do
    # Extract condition (everything until 'do')
    {condition_tokens, do_rest} = extract_until_nested(tokens, ["do"], ["if", "fi", "for", "done", "while"])
    {condition, _} = parse_command_or_pipeline(condition_tokens, original_input)

    # Skip the 'do' token
    rest = case do_rest do
      [{:command, "do"} | rest_tokens] -> rest_tokens
      _ -> do_rest
    end

    # Check for redirections at the end of the body
    {body_tokens, redirects, done_rest} = extract_body_with_redirects(rest, "done")

    # Parse the body as a complete script
    body = parse_tokens(body_tokens, "")

    # Add redirections to the condition if present
    condition = if redirects != [] do
      %{condition | redirects: condition.redirects ++ redirects}
    else
      condition
    end

    # Skip the 'done' token and don't include it in the script
    rest = case done_rest do
      [{:command, "done"} | rest_tokens] -> rest_tokens
      _ -> done_rest
    end

    # Create while loop AST node with minimal source info
    source_info = SourceInfo.new("")
    loop = %AST.Loop{type: :while, condition: condition, body: body, source_info: source_info}
    {loop, rest}
  end

  # Helper function to extract body with redirections
  defp extract_body_with_redirects(tokens, end_keyword) do
    # First, find the 'done' token, respecting nested structures
    {body_tokens, rest} = extract_until_nested(tokens, [end_keyword], ["if", "fi", "for", "while", "do"])

    # Check if there are redirections after the body but before 'done'
    case rest do
      [{:command, ^end_keyword}, {:redirect_input, _}, {:string, target} | rest_tokens] ->
        source_info = SourceInfo.new("")
        redirect = %AST.Redirect{type: :input, target: target, source_info: source_info}
        {body_tokens, [redirect], [{:command, end_keyword} | rest_tokens]}

      _ ->
        {body_tokens, [], rest}
    end
  end

  # Helper function to extract tokens until a specific keyword
  defp extract_until(tokens, keywords_or_keyword)

  # Main extract_until function with simpler semantics - no nesting awareness
  # For non-control structure keywords or cases where nesting doesn't matter
  defp extract_until(tokens, keywords) when is_list(keywords) do
    extract_until_helper(tokens, [], keywords)
  end

  defp extract_until(tokens, keyword) when is_binary(keyword) do
    # Delegate to extract_until_nested for control structure keywords
    if keyword in ["if", "fi", "for", "done", "while", "do", "then", "else"] do
      extract_until_nested(tokens, [keyword], ["if", "fi", "for", "done", "while", "do", "then", "else"])
    else
      extract_until_helper(tokens, [], [keyword])
    end
  end

  # Helper for non-nested extraction (original simpler version)
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

  # Special helper that respects nesting of control structures like for/do/done
  defp extract_until_nested(tokens, end_keywords, nested_keywords) do
    # Use a stack to track nested structures for better handling of diverse nesting
    structure_stack = []
    extract_until_nested_helper(tokens, [], end_keywords, nested_keywords, structure_stack)
  end

  # Helper for tracking nested structures
  defp extract_until_nested_helper([], acc, _end_keywords, _nested_keywords, _structure_stack) do
    {Enum.reverse(acc), []}
  end

  defp extract_until_nested_helper([{:command, word} | rest] = tokens, acc, end_keywords, nested_keywords, structure_stack) do
    # Update the structure stack based on control keywords
    new_stack = cond do
      # Push structures onto stack
      word == "if" ->
        ["if" | structure_stack]

      word == "for" ->
        ["for" | structure_stack]

      word == "while" ->
        ["while" | structure_stack]

      # Pop structures from stack
      word == "fi" && List.first(structure_stack) == "if" ->
        Enum.drop(structure_stack, 1)

      word == "done" && List.first(structure_stack) in ["for", "while"] ->
        Enum.drop(structure_stack, 1)

      # Handle mismatched tokens gracefully
      word == "fi" || word == "done" ->
        # Only pop if there's matching structures to pop
        if Enum.empty?(structure_stack) do
          structure_stack
        else
          Enum.drop(structure_stack, 1)
        end

      # Other keywords don't affect the stack
      true ->
        structure_stack
    end

    # Check if we're at a top-level end keyword
    is_top_level_end = word in end_keywords && Enum.empty?(new_stack)

    if is_top_level_end do
      {Enum.reverse(acc), rest}  # Return the rest without the end keyword
    else
      extract_until_nested_helper(rest, [{:command, word} | acc], end_keywords, nested_keywords, new_stack)
    end
  end

  defp extract_until_nested_helper([token | rest], acc, end_keywords, nested_keywords, structure_stack) do
    extract_until_nested_helper(rest, [token | acc], end_keywords, nested_keywords, structure_stack)
  end
end
