defmodule Stargate do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Stargate.Gate, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :simple_one_for_one, name: Stargate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
    Initiates a new gate with the given `aGate` name.
  """
  def initiate(aGate) do
    Supervisor.start_child(Stargate.Supervisor, [aGate])
  end
  
  defstruct [:source, :destination]
  #defstruct [:send, :receive] // TODO: This is wrong. it belongs to the module.

  @doc """
    Starts transfering `aObjectList` from `aSource` to `aDestination`.
  """
  def transfer_start(aSource, aDestination, aObjectList) do
    # First add all objects to the Stargate here.
    for zObject <- aObjectList do
      Stargate.Gate.send(aSource, zObject)
    end
    # Returns a Stargate struct we will use next
    %Stargate{source: aSource, destination: aDestination}
  end

  @doc """
    Send or receive an object from `aGate`
    Note: aSendOrReceive should be either
    `:send` or `:receive`.
  """
  def transfer(aGate, aSendOrReceive) do
    case aSendOrReceive do
      :send -> transfer_internal(aGate.source, aGate.destination)
      :receive -> transfer_internal(aGate.destination, aGate.source)
    end
    # Return the gate itself.
    aGate
  end

  @doc """
    Send an ObjectList, that's in the gates source,
    to the gates destination.
  """
  def transfer_internal(aSource, aDestination) do
    case Stargate.Gate.receive(aSource) do
      :error -> :ok
      {:ok, aHead} -> Stargate.Gate.send(aDestination, aHead)
    end
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
    Sends the `aObject` through the stargate.
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

defimpl Inspect, for: Stargate do
  @doc """
    Implementation of better printing of the state of stargate transfers.
  """
  def inspect(%Stargate{source: aSource, destination: aDestination}, _) do
    zGate_here = inspect(aSource)
    zGate_there = inspect(aDestination)

    zObjectList_here = inspect(Enum.reverse(Stargate.Gate.get(aSource)))
    zObjectList_there = inspect(Stargate.Gate.get(aDestination))

    zMax = max(String.length(zGate_here), String.length(zObjectList_here))

    """
    #Stargate<
      #{String.rjust(zGate_here, zMax)} <=> #{zGate_there}
      #{String.rjust(zObjectList_here, zMax)} <=> #{zObjectList_there}
    >
    """
  end
end
