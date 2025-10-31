defmodule BashInterpreter.AST do
  @moduledoc """
  Abstract Syntax Tree (AST) structures for the bash interpreter.
  These structures represent the parsed bash commands and expressions.
  """

  defmodule Script do
    @moduledoc """
    Represents a script, which is a sequence of commands.
    """
    defstruct commands: []
    @type t :: %__MODULE__{
      commands: [Command.t() | Pipeline.t() | Conditional.t() | Loop.t()]
    }
  end

  defmodule Command do
    @moduledoc """
    Represents a simple command with a name and arguments.
    """
    defstruct name: nil, args: [], redirects: []
    @type t :: %__MODULE__{
      name: String.t(),
      args: [String.t()],
      redirects: [Redirect.t()]
    }
  end

  defmodule Pipeline do
    @moduledoc """
    Represents a pipeline of commands.
    """
    defstruct commands: []
    @type t :: %__MODULE__{
      commands: [Command.t()]
    }
  end

  defmodule Redirect do
    @moduledoc """
    Represents a redirection (>, >>, <).
    """
    defstruct type: nil, target: nil
    @type redirect_type :: :input | :output | :append
    @type t :: %__MODULE__{
      type: redirect_type,
      target: String.t()
    }
  end

  defmodule Conditional do
    @moduledoc """
    Represents an if/else conditional structure.
    """
    defstruct condition: nil, then_branch: nil, else_branch: nil
    @type t :: %__MODULE__{
      condition: Command.t() | Pipeline.t(),
      then_branch: Script.t(),
      else_branch: Script.t() | nil
    }
  end

  defmodule Loop do
    @moduledoc """
    Represents a loop structure (for, while).
    """
    defstruct type: nil, condition: nil, body: nil
    @type loop_type :: :for | :while
    @type t :: %__MODULE__{
      type: loop_type,
      condition: any(),  # Can be a variable list for 'for' or a command for 'while'
      body: Script.t()
    }
  end

  defmodule Assignment do
    @moduledoc """
    Represents a variable assignment.
    """
    defstruct name: nil, value: nil
    @type t :: %__MODULE__{
      name: String.t(),
      value: String.t() | Command.t()  # Value can be a string or command substitution
    }
  end

  defmodule Subshell do
    @moduledoc """
    Represents a subshell execution.
    """
    defstruct script: nil
    @type t :: %__MODULE__{
      script: Script.t()
    }
  end
end