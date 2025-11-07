defmodule BashInterpreter.Walkers.InspectWalker do
  @moduledoc """
  Inspect walker that uses IO.inspect to visualize the AST structure.
  This provides a simple way to debug and understand the AST contents.
  """

  alias BashInterpreter.AST
  alias BashInterpreter.ASTWalker

  def walk_script(%AST.Script{commands: commands}, _opts) do
    IO.puts("=== Script AST ===")
    IO.inspect(commands, label: "Commands")
    commands
  end

  def walk_command(%AST.Command{name: name, args: args, redirects: redirects}, _opts) do
    IO.puts("=== Command AST ===")
    IO.inspect(name, label: "Name")
    IO.inspect(args, label: "Arguments")
    IO.inspect(redirects, label: "Redirects")
    %AST.Command{name: name, args: args, redirects: redirects}
  end

  def walk_pipeline(%AST.Pipeline{commands: commands}, _opts) do
    IO.puts("=== Pipeline AST ===")
    IO.inspect(commands, label: "Pipeline Commands")
    %AST.Pipeline{commands: commands}
  end

  def walk_conditional(%AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}, _opts) do
    IO.puts("=== Conditional AST ===")
    IO.inspect(condition, label: "Condition")
    IO.inspect(then_branch, label: "Then Branch")
    IO.inspect(else_branch, label: "Else Branch")
    %AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}
  end

  def walk_loop(%AST.Loop{type: type, condition: condition, body: body}, _opts) do
    IO.puts("=== Loop AST ===")
    IO.inspect(type, label: "Loop Type")
    IO.inspect(condition, label: "Loop Condition")
    IO.inspect(body, label: "Loop Body")
    %AST.Loop{type: type, condition: condition, body: body}
  end

  def walk_assignment(%AST.Assignment{name: name, value: value}, _opts) do
    IO.puts("=== Assignment AST ===")
    IO.inspect(name, label: "Variable Name")
    IO.inspect(value, label: "Variable Value")
    %AST.Assignment{name: name, value: value}
  end

  def walk_subshell(%AST.Subshell{script: script}, _opts) do
    IO.puts("=== Subshell AST ===")
    IO.inspect(script, label: "Subshell Script")
    %AST.Subshell{script: script}
  end

  def walk_redirect(%AST.Redirect{type: type, target: target}, _opts) do
    IO.puts("=== Redirect AST ===")
    IO.inspect(type, label: "Redirect Type")
    IO.inspect(target, label: "Redirect Target")
    %AST.Redirect{type: type, target: target}
  end

  def walk_default(node, _opts) do
    IO.puts("=== Unknown AST Node ===")
    IO.inspect(node, label: "Raw Node")
    node
  end
end
