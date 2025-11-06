defmodule BashInterpreter.Walkers.PrettyPrintWalker do
  @moduledoc """
  Pretty-print walker that displays the AST structure in a beautiful ASCII tree format.

  Creates output that looks like:
  Script
  └── echo hello
      ├── Arguments: hello world
      ├── Redirects: > output.txt
      └── Pipeline
          ├─ ls
          └─ grep pattern
  """

  alias BashInterpreter.AST
  alias BashInterpreter.ASTWalker

  @doc """
  Walks a Script node and returns a tree-formatted string.
  """
  def walk_script(%AST.Script{commands: commands}, _opts) do
    spaces = ""
    indent = 0

    # Clean, simple tree format
    if Enum.empty?(commands) do
      "#{spaces}└─ (empty)"
    else
      ["#{spaces}Script"]
      |> then(& add_commands(&1, commands, spaces))
      |> Enum.join("\n")
    end
  end

  @doc """
  Walks a Command node and returns a tree-formatted string.
  """
  def walk_command(%AST.Command{name: name, args: args, redirects: redirects}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    # Clean tree format: name args [redirections]
    main_line_prefix = if indent > 0, do: "#{spaces}└─ ", else: ""
    args_str = if !Enum.empty?(args), do: " #{Enum.join(args, " ")}", else: ""
    redirects_str = if !Enum.empty?(redirects) do
      " [#{format_redirects(redirects)}]"
    else
      ""
    end

    "#{main_line_prefix}#{name}#{args_str}#{redirects_str}"
  end

  @doc """
  Walks a Pipeline node and returns a tree-formatted string.
  """
  def walk_pipeline(%AST.Pipeline{commands: commands}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    command_lines = commands
                 |> Enum.with_index(1)
                 |> Enum.flat_map(fn {cmd, index} ->
                   last? = index == length(commands)
                   branch_prefix = if last?, do: spaces <> "   └─ ", else: spaces <> "   ├─ "

                   # Handle the nested command
                   nested_result = ASTWalker.walk(cmd, __MODULE__, [indent: indent + 6])
                   result_lines = if is_binary(nested_result),
                                 do: String.split(nested_result, "\n"),
                                 else: [inspect(nested_result)]

                   # Replace the indent level in nested results
                   processed_lines = Enum.with_index(result_lines)
                                     |> Enum.map(fn {line, line_idx} ->
                                       if line_idx == 0 do
                                         String.replace(line, String.duplicate(" ", indent + 6), branch_prefix)
                                       else
                                         String.replace(line, String.duplicate(" ", if(last?, do: indent + 6, else: indent + 9)), spaces <> "   ")
                                       end
                                     end)

                   processed_lines
                 end)

    "#{spaces}└─ Pipeline (#{length(commands)})\n#{Enum.join(command_lines, "\n")}"
  end

  @doc """
  Walks a Conditional node and returns a tree-formatted string.
  """
  def walk_conditional(%AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    condition_str = ASTWalker.walk(condition, __MODULE__, [indent: indent + 3])
    then_str = ASTWalker.walk(then_branch, __MODULE__, [indent: indent + 3])

    base_lines = [
      "#{spaces}└─ If",
      "#{spaces}   ├─ Condition: #{String.replace(condition_str, "\n", "\n   │   ")}",
      "#{spaces}   └─ Then"
    ]

    body_lines = add_multiline_content(spaces <> "      ", then_str)
    base_lines ++ body_lines
    |> then(fn lines ->
      if else_branch do
        else_str = ASTWalker.walk(else_branch, __MODULE__, [indent: indent + 3])
        else_lines = add_multiline_content(spaces <> "   └─ Else", else_str)
        lines ++ else_lines
      else
        lines
      end
    end)
  end

  @doc """
  Walks a Loop node and returns a tree-formatted string.
  """
  def walk_loop(%AST.Loop{type: type, condition: condition, body: body}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    condition_str = case type do
      :for ->
        var = condition.variable
        items = Enum.join(condition.items, " ")
        "for #{var} in #{items}"
      :while ->
        ASTWalker.walk(condition, __MODULE__, [indent: indent + 6])
    end

    body_str = ASTWalker.walk(body, __MODULE__, [indent: indent + 6])

    base_lines = [
      "#{spaces}└─ #{String.capitalize(to_string(type))} Loop",
      "#{spaces}   ├─ Condition: #{condition_str}",
      "#{spaces}   └─ Body"
    ]

    body_lines = add_multiline_content(spaces <> "      ", body_str)
    base_lines ++ body_lines
  end

  @doc """
  Walks an Assignment node and returns a tree-formatted string.
  """
  def walk_assignment(%AST.Assignment{name: name, value: value}, _opts) do
    "#{name}=#{inspect(value)}"
  end

  @doc """
  Walks a Subshell node and returns a tree-formatted string.
  """
  def walk_subshell(%AST.Subshell{script: script}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    script_str = ASTWalker.walk(script, __MODULE__, [indent: indent + 6])

    [
      "#{spaces}└─ Subshell",
      "#{spaces}   └─ Commands"
    ]
    |> then(fn lines ->
      add_multiline_content(spaces <> "      ", script_str)
      |> then(& lines ++ &1)
    end)
  end

  @doc """
  Walks a Redirect node and returns a tree-formatted string.
  """
  def walk_redirect(%AST.Redirect{type: type, target: target}, _opts) do
    symbol = case type do
      :output -> ">"
      :input -> "<"
      :append -> ">>"
      _ -> "?"
    end
    "#{symbol} #{target}"
  end

  @doc """
  Default walker for unknown node types.
  """
  def walk_default(node, _opts) do
    inspect(node)
  end

  # Helper functions

  defp format_redirects(redirects) do
    if Enum.empty?(redirects) do
      ""
    else
      redirects
      |> Enum.map(fn %AST.Redirect{type: type, target: target} ->
        case type do
          :output -> "> #{target}"
          :input -> "< #{target}"
          :append -> ">> #{target}"
          _ -> "#{type} #{target}"
        end
      end)
      |> Enum.join(", ")
    end
  end

  defp add_commands(lines, commands, parent_prefix) do
    if Enum.empty?(commands) do
      lines ++ ["#{parent_prefix}└─ (empty)"]
    else
      commands
      |> Enum.with_index()
      |> Enum.reduce(lines, fn {cmd, index}, acc ->
        last? = index == length(commands) - 1
        line_prefix = if last?, do: "└─ ", else: "├─ "

        result = ASTWalker.walk(cmd, __MODULE__, [indent: 4])
        result_str = if is_list(result), do: Enum.join(result, "\n"), else: result

        processed = String.replace_prefix(result_str, "└─ ", "#{parent_prefix}#{line_prefix}")
        acc ++ String.split(processed, "\n")
      end)
    end
  end

  defp add_multiline_content(prefix, multiline_str) do
    if multiline_str == "" or multiline_str == "\n" do
      ["#{prefix}└─ (empty)"]
    else
      multiline_str
      |> String.split("\n")
      |> Enum.flat_map(fn line ->
        case String.trim(line) do
          "" -> []
          _ -> [String.replace_prefix(line, "└─ ", "#{prefix}└─ ")]
        end
      end)
    end
  end
end
