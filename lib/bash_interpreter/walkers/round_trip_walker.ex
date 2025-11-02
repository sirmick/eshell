defmodule BashInterpreter.Walkers.RoundTripWalker do
  @moduledoc """
  Round-trip walker that can reproduce bash code from AST nodes.

  This walker implements the ASTWalker behavior and has two modes:
  1. Exact mode - uses stored source_info to reproduce the original text
  2. Synthesis mode - generates equivalent bash code from the AST structure
  """

  alias BashInterpreter.AST
  alias BashInterpreter.ASTWalker

  # Script node handling
  def walk_script(%AST.Script{commands: commands, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      commands
      |> Enum.map(fn command -> ASTWalker.walk(command, __MODULE__, opts) end)
      |> Enum.join("\n")
    end
  end

  # Command node handling
  def walk_command(%AST.Command{name: command_name, args: args, redirects: redirects, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      # Format arguments
      args_str = format_args(args)

      # Format redirections
      redirects_str = format_redirects(redirects, opts)

      # Combine everything
      "#{command_name}#{if args_str != "", do: " " <> args_str, else: ""}#{redirects_str}"
    end
  end

  # Pipeline node handling
  def walk_pipeline(%AST.Pipeline{commands: commands, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      commands
      |> Enum.map(fn command -> ASTWalker.walk(command, __MODULE__, opts) end)
      |> Enum.join(" | ")
    end
  end

  # Redirect node handling
  def walk_redirect(%AST.Redirect{type: type, target: target, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      case type do
        :input -> "< #{target}"
        :output -> "> #{target}"
        :append -> ">> #{target}"
        _ -> ""
      end
    end
  end

  # Conditional (if/else) node handling
  def walk_conditional(%AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      # Format condition
      condition_str = ASTWalker.walk(condition, __MODULE__, opts)

      # Format then branch
      then_str = ASTWalker.walk(then_branch, __MODULE__, opts)

      # Check if original format had newlines
      if String.contains?(then_str, "\n") do
        # Multi-line format with indentation
        then_indented = indent_lines(then_str)

        # Handle else branch if it exists
        if else_branch do
          else_str = ASTWalker.walk(else_branch, __MODULE__, opts)
          else_indented = indent_lines(else_str)
          "if #{condition_str}; then\n#{then_indented}\nelse\n#{else_indented}\nfi"
        else
          "if #{condition_str}; then\n#{then_indented}\nfi"
        end
      else
        # Single-line format
        if else_branch do
          else_str = ASTWalker.walk(else_branch, __MODULE__, opts)
          "if #{condition_str}; then #{then_str}; else #{else_str}; fi"
        else
          "if #{condition_str}; then #{then_str}; fi"
        end
      end
    end
  end

  # Loop node handling
  def walk_loop(%AST.Loop{type: type, condition: condition, body: body, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      body_str = ASTWalker.walk(body, __MODULE__, opts)
      multiline = String.contains?(body_str, "\n")

      case type do
        :for ->
          # Format for loop
          variable = condition.variable
          items = Enum.join(condition.items, " ")

          # Multi-line or single-line format
          if multiline do
            body_indented = indent_lines(body_str)
            "for #{variable} in #{items}; do\n#{body_indented}\ndone"
          else
            "for #{variable} in #{items}; do #{body_str}; done"
          end

        :while ->
          # Format while loop
          condition_str = ASTWalker.walk(condition, __MODULE__, opts)

          # Multi-line or single-line format
          if multiline do
            body_indented = indent_lines(body_str)
            "while #{condition_str}; do\n#{body_indented}\ndone"
          else
            "while #{condition_str}; do #{body_str}; done"
          end

        _ -> ""
      end
    end
  end

  # Assignment node handling
  def walk_assignment(%AST.Assignment{name: name, value: value, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      "#{name}=#{value}"
    end
  end

  # Subshell node handling
  def walk_subshell(%AST.Subshell{script: script, source_info: source_info}, opts) do
    if opts[:exact] && source_info && source_info.text != "" do
      source_info.text
    else
      script_str = ASTWalker.walk(script, __MODULE__, opts)
      "(#{script_str})"
    end
  end

  # Default handler for unknown node types
  def walk_default(_node, _opts) do
    ""
  end

  # Helper: Format arguments with proper quoting
  defp format_args(args) do
    args
    |> Enum.map(fn arg ->
      cond do
        # Command substitutions should be preserved as-is
        is_binary(arg) && String.starts_with?(arg, "$(") && String.ends_with?(arg, ")") ->
          arg
        # Variables - preserve as-is
        is_binary(arg) && String.starts_with?(arg, "$") ->
          arg
        # Quote strings with spaces or special characters
        is_binary(arg) && (String.contains?(arg, " ") ||
                          String.contains?(arg, ";") ||
                          String.contains?(arg, "|") ||
                          String.contains?(arg, "<") ||
                          String.contains?(arg, ">") ||
                          String.contains?(arg, "&")) ->
          "\"#{arg}\""
        # Default case - just use the argument
        true ->
          arg
      end
    end)
    |> Enum.join(" ")
  end

  # Helper: Format redirections
  defp format_redirects(redirects, opts) do
    if redirects && length(redirects) > 0 do
      redirect_strs = Enum.map(redirects, fn redirect ->
        ASTWalker.walk(redirect, __MODULE__, opts)
      end)
      " " <> Enum.join(redirect_strs, " ")
    else
      ""
    end
  end

  # Helper: Indent lines for pretty-printing
  defp indent_lines(text) do
    text
    |> String.split("\n")
    |> Enum.map(fn line -> if String.trim(line) != "", do: "  #{line}", else: line end)
    |> Enum.join("\n")
  end
end
