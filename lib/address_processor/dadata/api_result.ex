defmodule AddressProcessor.Dadata.ApiResult do
  defstruct suggestion_count: 0,
            fias_id: nil,
            fias_code: nil
  
  @type t :: %{
    suggestion_count: integer,
    fias_id: binary | nil,
    fias_code: binary | nil
  }
end