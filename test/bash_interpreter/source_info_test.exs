defmodule BashInterpreter.SourceInfoTest do
  use ExUnit.Case

  alias BashInterpreter.AST.SourceInfo

  test "creates SourceInfo with text and position" do
    text = "echo hello"
    source_info = SourceInfo.new(text, 1, 1)

    assert source_info.text == "echo hello"
    assert source_info.line == 1
    assert source_info.column == 1
    assert source_info.end_line == 1
    assert source_info.end_column == 11  # length of "echo hello"
  end

  test "creates SourceInfo with multiline text" do
    text = "echo hello\necho world"
    source_info = SourceInfo.new(text, 1, 1)

    assert source_info.text == "echo hello\necho world"
    assert source_info.line == 1
    assert source_info.column == 1
    assert source_info.end_line == 2
    assert source_info.end_column == 11  # length of "echo world"
  end

  test "creates SourceInfo from range in original text" do
    original_text = "echo hello world"
    source_info = SourceInfo.from_range(original_text, 5, 10)

    assert source_info.text == "hello"
    assert source_info.line == 1
    assert source_info.column == 6  # position 5 + 1 for 1-based indexing
    assert source_info.end_line == 1
    assert source_info.end_column == 10  # position 9 + 1 for 1-based indexing
  end

  test "converts position to line and column" do
    text = "echo hello\necho world"

    {line, column} = SourceInfo.position_to_line_column(text, 0)
    assert line == 1
    assert column == 1

    {line, column} = SourceInfo.position_to_line_column(text, 5)
    assert line == 1
    assert column == 6

    # Position 12 is actually the letter 'e' in the second line "echo world"
    # In the string "echo hello\necho world", characters are 0-indexed
    # Index 10 is '\n', so index 11 is the start of the second line, and index 12 is the first 'e'
    {line, column} = SourceInfo.position_to_line_column(text, 12)
    assert line == 2
    assert column == 2  # First character of the second line, 1-indexed
  end
end
