defmodule BashInterpreter.AST do
  @moduledoc """
  Abstract Syntax Tree (AST) structures for the bash interpreter.
  These structures represent the parsed bash commands and expressions.
  """

  alias BashInterpreter.AST.SourceInfo

  defmodule Script do
    @moduledoc """
    Represents a script, which is a sequence of commands.
    """
    defstruct commands: [], source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      commands: [Command.t() | Pipeline.t() | Conditional.t() | Loop.t() | Assignment.t() | Subshell.t()],
      source_info: SourceInfo.t()
    }
  end

  defmodule Command do
    @moduledoc """
    Represents a simple command with a name and arguments.
    """
    defstruct name: nil, args: [], redirects: [], source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      name: String.t(),
      args: [String.t()],
      redirects: [Redirect.t()],
      source_info: SourceInfo.t()
    }
  end

  defmodule Pipeline do
    @moduledoc """
    Represents a pipeline of commands.
    """
    defstruct commands: [], source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      commands: [Command.t()],
      source_info: SourceInfo.t()
    }
  end

  defmodule Redirect do
    @moduledoc """
    Represents a redirection (>, >>, <).
    """
    defstruct type: nil, target: nil, source_info: %SourceInfo{}
    @type redirect_type :: :input | :output | :append
    @type t :: %__MODULE__{
      type: redirect_type,
      target: String.t(),
      source_info: SourceInfo.t()
    }
  end

  defmodule Conditional do
    @moduledoc """
    Represents an if/else conditional structure.
    """
    defstruct condition: nil, then_branch: nil, else_branch: nil, source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      condition: Command.t() | Pipeline.t(),
      then_branch: Script.t(),
      else_branch: Script.t() | nil,
      source_info: SourceInfo.t()
    }
  end

  defmodule Loop do
    @moduledoc """
    Represents a loop structure (for, while).
    """
    defstruct type: nil, condition: nil, body: nil, source_info: %SourceInfo{}
    @type loop_type :: :for | :while
    @type t :: %__MODULE__{
      type: loop_type,
      condition: any(),  # Can be a variable list for 'for' or a command for 'while'
      body: Script.t(),
      source_info: SourceInfo.t()
    }
  end

  defmodule Assignment do
    @moduledoc """
    Represents a variable assignment.
    """
    defstruct name: nil, value: nil, source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      name: String.t(),
      value: String.t() | Command.t(),  # Value can be a string or command substitution
      source_info: SourceInfo.t()
    }
  end

  defmodule Subshell do
    @moduledoc """
    Represents a subshell execution.
    """
    defstruct script: nil, source_info: %SourceInfo{}
    @type t :: %__MODULE__{
      script: Script.t(),
      source_info: SourceInfo.t()
    }
  end
end
