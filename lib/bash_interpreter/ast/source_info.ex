defmodule BashInterpreter.AST.SourceInfo do
  @moduledoc """
  Source information for AST nodes.

  This module stores complete source information for each AST node,
  enabling perfect round-trip conversion from source to AST and back.
  """

  defstruct [:text, :line, :column, :end_line, :end_column]

  @type t :: %__MODULE__{
    text: String.t(),
    line: non_neg_integer(),
    column: non_neg_integer(),
    end_line: non_neg_integer(),
    end_column: non_neg_integer()
  }

  @doc """
  Creates a new SourceInfo struct with the given text and position.
  """
  def new(text, line \\ 1, column \\ 1)

  def new(text, line, column) when is_binary(text) do
    lines = String.split(text, "\n")
    end_line = line + length(lines) - 1
    # Keep the +1 fix for end_column calculation
    end_column = if length(lines) == 1, do: column + String.length(text), else: String.length(List.last(lines)) + 1

    %__MODULE__{
      text: text,
      line: line,
      column: column,
      end_line: end_line,
      end_column: end_column
    }
  end

  # Handle case where text is already a SourceInfo struct
  def new(%__MODULE__{} = source_info, _line, _column) do
    source_info
  end

  @doc """
  Creates a SourceInfo struct from a range in the original text.
  """
  def from_range(original_text, start_pos, end_pos) do
    text = String.slice(original_text, start_pos, end_pos - start_pos)
    {line, column} = position_to_line_column(original_text, start_pos)
    {end_line, end_column} = position_to_line_column(original_text, end_pos - 1)

    %__MODULE__{
      text: text,
      line: line,
      column: column,
      end_line: end_line,
      end_column: end_column
    }
  end

  @doc """
  Converts a character position to line and column.
  @doc """
  Converts a position to line and column.
  """
  def position_to_line_column(text, pos) do
    lines = String.split(text, "\n")

    {line, column} = find_position_in_lines(lines, pos, 1, 0)
    {line, column}
  end

  # Helper function to find the line and column for a given position
  defp find_position_in_lines([], _pos, line, _acc), do: {line, 1}

  defp find_position_in_lines([current_line | rest], pos, line, acc) do
    line_length = String.length(current_line) + 1  # +1 for newline

    if pos < acc + line_length do
      # Special case for newline character position
      if pos == acc + String.length(current_line) do
        {line + 1, 1}
      else
        {line, pos - acc + 1}  # +1 for 1-based indexing
      end
    else
      find_position_in_lines(rest, pos, line + 1, acc + line_length)
    end
  end
end
