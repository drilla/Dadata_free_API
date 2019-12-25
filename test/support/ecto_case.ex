defmodule AddressProcessor.Support.EctoCase do
  use ExUnit.CaseTemplate
  using do
    quote do
      alias AddressProcessor.AddressProvider.Repo
      
      import Ecto
      import Ecto.Query
      import AddressProcessor.Support.EctoCase
      
    end
  end
  
  alias AddressProcessor.AddressProvider.Repo

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end
end
