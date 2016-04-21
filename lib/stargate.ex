defmodule Stargate do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Stargate.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stargate.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  defstruct [:here, :there]

  @doc """
    Starts transfering `aObjectList` from `aHere` to `aThere`.
  """
  def transfer(aHere, aThere, aObjectList) do
    # First add all objects to the Stargate here.
    for zObject <- aObjectList do
      Stargate.Gate.send(aHere, zObject)
    end
    # Returns a Stargate struct we will use next
    %Stargate{here: aHere, there: aThere}
  end

  @doc """
    Sends an object to the `aGate` there.
  """
  def send_there(aGate) do
    # See if we can send data from here. If so, send
    # the sent data to there. Otherwise, do nothing.
    case Stargate.Gate.send(aGate.here) do
      :error -> :ok
      {:ok, aHead} -> Stargate.Gate.send(aGate.there, aHead)
    end
    # Return the gate itself. 
    aGate
  end
end

defmodule Stargate.Gate do
  @doc """
    Creates a gate with the given `aName`.
    The name is used to identify the gate, instead of using a PID.
  """
  def start_link(aName) do
    Agent.start_link(fn -> [] end, name: aName)
  end

  @doc """
    Get the data currently in the `aGate`.
  """
  def get(aGate) do
    Agent.get(aGate, fn list -> list end)
  end

  @doc """
    Sends the `aObject` currently through the stargate.
  """
  def send(aGate, aObject) do
    Agent.update(aGate, fn list -> [aObject|list] end)
  end

  @doc """
    Receives an object from the `aGate`.
    Returns `{:ok, aObject}` if there is an object
    or `:error` if the stargate is currently empty.
  """
  def receive(aGate) do
    Agent.get_and_update(aGate, fn
      [] -> {:error, []}
      [zHead|zTail] -> {{:ok, zHead}, zTail}
    end)
  end
end
