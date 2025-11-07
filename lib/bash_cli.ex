defmodule BashCli do
  @moduledoc """
  Command line interface for the Bash Interpreter.

  This CLI can read bash files, parse them into AST, and visualize them
  using different walkers (pretty_print, inspect, json, etc.).
  """

  alias BashInterpreter
  alias BashInterpreter.ASTWalker

  @available_walkers [
    {"pretty_print", BashInterpreter.Walkers.PrettyPrintWalker, "Pretty print the AST in tree format"},
    {"inspect", BashInterpreter.Walkers.InspectWalker, "Use IO.inspect to visualize the AST"},
    {"json", BashInterpreter.Walkers.JSONWalker, "Output AST as JSON"},
    {"round_trip", BashInterpreter.Walkers.RoundTripWalker, "Convert AST back to bash syntax"}
  ]

  @doc """
  Main entry point for the CLI.

  Usage:
    mix run lib/bash_cli.ex <filename> [walker_type]

  Available walkers: #{Enum.map_join(@available_walkers, ", ", fn {name, _, desc} -> name end)}
  """
  def main(args) do
    case parse_args(args) do
      {:ok, filename, walker_name} ->
        run_cli(filename, walker_name)

      {:error, :missing_filename} ->
        IO.puts("Error: Missing filename")
        print_usage()

      {:error, :invalid_walker, name} ->
        IO.puts("Error: Invalid walker '#{name}'")
        print_available_walkers()
        print_usage()

      {:error, reason} ->
        IO.puts("Error: #{reason}")
        print_usage()
    end
  end

  defp parse_args(args) do
    case args do
      [] -> {:error, :missing_filename}
      [filename] -> {:ok, filename, "pretty_print"}
      [filename, walker_name] -> validate_walker(filename, walker_name)
      _ -> {:error, :too_many_args}
    end
  end

  defp validate_walker(filename, walker_name) do
    if Enum.any?(@available_walkers, fn {name, _, _} -> name == walker_name end) do
      {:ok, filename, walker_name}
    else
      {:error, :invalid_walker, walker_name}
    end
  end

  defp run_cli(filename, walker_name) do
    case read_file(filename) do
      {:ok, content} ->
        IO.puts("=== Parsing bash file: #{filename} ===")
        IO.puts("Content:")
        IO.puts(content)
        IO.puts("\n=== AST Generated ===")

        ast = BashInterpreter.parse(content)
        walk_ast(ast, walker_name)

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
    end
  end

  defp read_file(filename) do
    case File.read(filename) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  defp walk_ast(ast, walker_name) do
    {_, walker_module, _} = Enum.find(@available_walkers, fn {name, _, _} -> name == walker_name end)

    IO.puts("\n=== Using #{walker_name} walker ===")

    result = case walker_name do
      "json" ->
        # JSONWalker has a special to_json function
        BashInterpreter.to_json(ast)

      "round_trip" ->
        # RoundTripWalker should convert back to bash syntax
        ASTWalker.walk(ast, walker_module, exact: true)

      _ ->
        # Standard walker
        ASTWalker.walk(ast, walker_module)
    end

    # Handle the result appropriately
    case result do
      string when is_binary(string) ->
        IO.puts("Result:")
        IO.puts(string)

      list when is_list(list) ->
        IO.puts("Result:")
        IO.puts(Enum.join(Enum.map(list, &inspect/1), "\n"))

      other ->
        IO.puts("Result:")
        IO.inspect(other)
    end

    IO.puts("\n✓ Walker execution completed successfully")
  end

  defp print_usage do
    IO.puts("""
    Usage:
      mix run lib/bash_cli.ex <filename> [walker_type]

    Arguments:
      filename     - Path to the bash file to parse
      walker_type  - Optional walker to use for visualization (default: pretty_print)
    """)
    print_available_walkers()
  end

  defp print_available_walkers do
    IO.puts("Available walkers:")
    Enum.each(@available_walkers, fn {name, _, description} ->
      IO.puts("  #{name} - #{description}")
    end)
  end
end

# Entry point when run directly
if System.argv() != [] do
  BashCli.main(System.argv())
else
  IO.puts("Error: No arguments provided")
  BashCli.print_usage()
end
