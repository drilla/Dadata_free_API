defmodule AddressProcessor.AddressProvider.Api do
  @moduledoc """
  Provide adresses from external source(DB in case)
  """

  alias AddressProcessor.AddressProvider.Repo
  alias AddressProcessor.AddressProvider.Address

  import Ecto.Query
  @doc """
    get one address with undefined code
  """
  def get_address_without_code() do
    Address
    |> where_no_fias_codes()
#    |> where([a], a.id not in ^excluded_ids)
    |> where([a], a.not_found != true or is_nil(a.not_found))

    
    |> first()
    |> Repo.one()
  end

  @doc "updates all  entities with given address at once"
  def update_same_addresses(%Address{address: address}, fias_code, fias_id) do
    query = 
      from a in Address,
      where: a.address == ^address
    Repo.update_all(query,  set: [fias_id: fias_id, fias_code: fias_code])
  end

  @doc "mark one addres not found in api"
  def mark_as_not_found(%Address{id: _id} = address) do
    Ecto.Changeset.change(address, not_found: true) |>
    Repo.update!()
  end

  def count_without_fias_data() do
    Address
    |> where_no_fias_codes()
    |> where([a], a.not_found != true or is_nil(a.not_found))
    |> select(count("*")) 
    |> Repo.one()
  end

  defp where_no_fias_codes(query) do
    query 
    |> where([a], is_nil(a.fias_code) )
  end
end
