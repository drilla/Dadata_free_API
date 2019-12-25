 defmodule AddressProcessor.AddressProvider.Address do
    use Ecto.Schema

    schema "address_items_2" do
        field :address, :string
        field :fias_id, :string
        field :fias_code, :string
        field :not_found, :boolean
    end

    def changeset(address, params \\ %{}) do
        address 
        |> Ecto.Changeset.cast(params, [:fias_id, :fias_code, :not_found])
        |> Ecto.Changeset.validate_required([:fias_id , :fias_code])
    end  
end