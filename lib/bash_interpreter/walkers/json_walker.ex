defmodule BashInterpreter.Walkers.JSONWalker do
  @moduledoc """
  JSON walker that displays the AST structure as clean JSON output for debugging.
  """

  alias BashInterpreter.AST

  @doc """
  Walks a Script node and returns JSON representation.
  """
  def walk_script(%AST.Script{commands: commands}, _opts) do
    if Enum.empty?(commands) do
      %{type: "script", commands: []}
    else
      command_json = Enum.map(commands, &walk_command_list/1)
      %{type: "script", commands: command_json}
    end
  end

  defp walk_command_list(node) do
    cond do
      is_struct(node, AST.Command) ->
        walk_command(node, [])
      is_struct(node, AST.Conditional) ->
        walk_conditional(node, [])
      is_struct(node, AST.Loop) ->
        walk_loop(node, [])
      is_struct(node, AST.Pipeline) ->
        walk_pipeline(node, [])
      true ->
        walk_default(node, [])
    end
  end

  @doc """
  Walks a Command node and returns JSON representation.
  """
  def walk_command(%AST.Command{name: name, args: args, redirects: redirects}, _opts) do
    %{
      type: "command",
      name: name,
      args: args,
      redirects: Enum.map(redirects, &walk_redirect(&1, []))
    }
  end

  @doc """
  Walks a Pipeline node and returns JSON representation.
  """
  def walk_pipeline(%AST.Pipeline{commands: commands}, opts) do
    %{
      type: "pipeline",
      commands: Enum.map(commands, &walk_default(&1, opts))
    }
  end

  @doc """
  Walks a Conditional node and returns JSON representation.
  """
  def walk_conditional(%AST.Conditional{condition: condition, then_branch: then_branch, else_branch: else_branch}, _opts) do
    base = %{
      type: "conditional",
      condition: walk(condition, __MODULE__, []),
      then_branch: walk(then_branch, __MODULE__, [])
    }

    if else_branch do
      Map.put(base, :else_branch, walk(else_branch, __MODULE__))
    else
      base
    end
  end

  @doc """
  Walks a Loop node and returns JSON representation.
  """
  def walk_loop(%AST.Loop{type: type, condition: condition, body: body}, _opts) do
    condition_json = case type do
      :for ->
        %{type: "for_loop", variable: condition.variable, items: condition.items}
      :while ->
        %{type: "while_loop", condition: walk(condition, __MODULE__, [])}
    end

    %{
      type: Atom.to_string(type) <> "_loop",
      condition: condition_json,
      body: walk(body, __MODULE__, [])
    }
  end

  @doc """
  Walks an Assignment node and returns JSON representation.
  """
  def walk_assignment(%AST.Assignment{name: name, value: value}, _opts) do
    %{
      type: "assignment",
      name: name,
      value: value
    }
  end

  @doc """
  Walks a Subshell node and returns JSON representation.
  """
  def walk_subshell(%AST.Subshell{script: script}, _opts) do
    %{
      type: "subshell",
      script: walk(script, __MODULE__, [])
    }
  end

  @doc """
  Walks a Redirect node and returns JSON representation.
  """
  def walk_redirect(%AST.Redirect{type: type, target: target}, _opts) do
    %{
      type: type,
      target: target
    }
  end

  @doc """
  Default walker for unknown node types.
  """
  def walk_default(node, opts) do
    case node do
      %AST.Command{} -> walk_command(node, opts)
      %AST.Pipeline{} -> walk_pipeline(node, opts)
      %AST.Conditional{} -> walk_conditional(node, opts)
      %AST.Loop{} -> walk_loop(node, opts)
      %AST.Assignment{} -> walk_assignment(node, opts)
      %AST.Subshell{} -> walk_subshell(node, opts)
      _ -> node
    end
  end

  @doc """
  Walks an AST node and returns JSON representation.

  The walker implementation should be a module that implements the walk/2 function
  for each AST node type.
  """
  def walk(ast_node, _walker_module, opts \\ []) do
    case ast_node do
      %AST.Script{} -> walk_script(ast_node, opts)
      %AST.Command{} -> walk_command(ast_node, opts)
      %AST.Pipeline{} -> walk_pipeline(ast_node, opts)
      %AST.Redirect{} -> walk_redirect(ast_node, opts)
      %AST.Conditional{} -> walk_conditional(ast_node, opts)
      %AST.Loop{} -> walk_loop(ast_node, opts)
      %AST.Assignment{} -> walk_assignment(ast_node, opts)
      %AST.Subshell{} -> walk_subshell(ast_node, [])
      _ -> walk_default(ast_node, opts)
    end
  end

  @doc """
  Returns JSON string representation of the AST.
  """
  def to_json(ast_node, opts \\ []) do
    json_map = walk(ast_node, __MODULE__, opts)

    # Try to use Jason if available, otherwise use basic string conversion
    if Code.ensure_loaded?(Jason) do
      case Jason.encode(json_map) do
        {:ok, encoded} -> encoded
        _ -> Jason.encode!(walk_default(ast_node, opts))
      end
    else
      # Fallback to basic string conversion for debugging
      inspect(json_map)
    end
  end
end
