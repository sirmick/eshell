defmodule BashInterpreter.Walkers.PrettyPrintWalker do
  @moduledoc """
  Pretty-print walker that displays the AST structure in a readable format.

  This walker implements the ASTWalker behavior to convert an AST to a
  human-readable representation of the structure.
  """

  alias BashInterpreter.AST
  alias BashInterpreter.ASTWalker

  @doc """
  Walks a Script node and returns a pretty-printed string.
  """
  def walk_script(%AST.Script{commands: commands}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    "#{spaces}Script\n" <>
    Enum.map(commands, fn cmd ->
      ASTWalker.walk(cmd, __MODULE__, [indent: indent + 2])
    end)
    |> Enum.join("\n")
  end

  @doc """
  Walks a Command node and returns a pretty-printed string.
  """
  def walk_command(%AST.Command{name: name, args: args, redirects: redirects}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    args_str = if Enum.empty?(args), do: "", else: " Args: #{inspect(args)}"
    redirects_str = if Enum.empty?(redirects),
      do: "",
      else: " Redirects: #{format_redirects(redirects)}"

    "#{spaces}└─ Command: #{name}#{args_str}#{redirects_str}"
  end

  defp format_redirects(redirects) do
    redirects
    |> Enum.map(fn
      %AST.Redirect{type: :output, target: target} -> "> #{target}"
      %AST.Redirect{type: :input, target: target} -> "< #{target}"
      %AST.Redirect{type: :append, target: target} -> ">> #{target}"
      _ -> ""
    end)
    |> Enum.join(", ")
    |> then(fn str -> "[#{str}]" end)
  end

  @doc """
  Walks a Pipeline node and returns a pretty-printed string.
  """
  def walk_pipeline(%AST.Pipeline{commands: commands}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    commands_count = length(commands)

    commands_str = commands
                 |> Enum.with_index(1)
                 |> Enum.map(fn {cmd, idx} ->
                   cmd_indent = indent + 2
                   cmd_opts = [indent: cmd_indent]
                   cmd_str = ASTWalker.walk(cmd, __MODULE__, cmd_opts)
                   prefix = if idx == commands_count, do: "└─", else: "├─"
                   "#{String.duplicate(" ", indent)}   #{prefix} #{String.trim_leading(cmd_str)}"
                 end)
                 |> Enum.join("\n")

    "#{spaces}└─ Pipeline\n#{commands_str}"
  end

  @doc """
  Walks a Redirect node and returns a pretty-printed string.
  """
  def walk_redirect(%AST.Redirect{type: type, target: target}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    type_str = case type do
      :output -> ">"
      :input -> "<"
      :append -> ">>"
      _ -> "?"
    end

    "#{spaces}└─ Redirect: #{type_str} #{target}"
  end

  @doc """
  Walks a Conditional node and returns a pretty-printed string.
  """
  def walk_conditional(%AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    condition_str = ASTWalker.walk(condition, __MODULE__, [indent: indent + 2])
    then_str = ASTWalker.walk(then_branch, __MODULE__, [indent: indent + 2])

    else_str = if else_branch do
      else_branch_str = ASTWalker.walk(else_branch, __MODULE__, [indent: indent + 2])
      "\n#{spaces}└─ Else:\n#{else_branch_str}"
    else
      ""
    end

    "#{spaces}└─ If\n" <>
    "#{spaces}   ├─ Condition:\n#{condition_str}\n" <>
    "#{spaces}   └─ Then:\n#{then_str}#{else_str}"
  end

  @doc """
  Walks a Loop node and returns a pretty-printed string.
  """
  def walk_loop(%AST.Loop{type: type, condition: condition, body: body}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    condition_str = case type do
      :for ->
        var = condition.variable
        items = inspect(condition.items)
        "#{spaces}  Variable: #{var}\n#{spaces}  Items: #{items}"

      :while ->
        ASTWalker.walk(condition, __MODULE__, [indent: indent + 2])
    end

    body_str = ASTWalker.walk(body, __MODULE__, [indent: indent + 2])

    "#{spaces}└─ #{String.capitalize(to_string(type))} Loop\n" <>
    "#{spaces}   ├─ Condition:\n#{condition_str}\n" <>
    "#{spaces}   └─ Body:\n#{body_str}"
  end

  @doc """
  Walks an Assignment node and returns a pretty-printed string.
  """
  def walk_assignment(%AST.Assignment{name: name, value: value}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    "#{spaces}└─ Assignment: #{name} = #{inspect(value)}"
  end

  @doc """
  Walks a Subshell node and returns a pretty-printed string.
  """
  def walk_subshell(%AST.Subshell{script: script}, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    script_str = ASTWalker.walk(script, __MODULE__, [indent: indent + 2])

    "#{spaces}└─ Subshell\n#{script_str}"
  end

  @doc """
  Default walker for unknown node types.
  """
  def walk_default(node, opts) do
    indent = Keyword.get(opts, :indent, 0)
    spaces = String.duplicate(" ", indent)

    "#{spaces}Unknown: #{inspect(node)}"
  end
end
