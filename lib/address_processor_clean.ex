defmodule AddressProcessorClean do
  @moduledoc """
    Processing addresses with undefinded fias codes
    uses dadata CLEAN api
  """

  alias AddressProcessor.AddressProvider.Api, as: AddressApi
  alias AddressProcessor.Dadata.ApiResult
  alias AddressProcessor.Dadata.ApiObjectData
  alias AddressProcessor.Dadata.CleanApi, as: DadataApi
  alias AddressProcessor.AddressProvider.Address
  alias AddressProcessor.AddressProvider.Repo  
  require Logger

  @doc "checking addresses one by one"
  def run do

    # TODO not found must be separated from other apis
    count = AddressApi.count_without_fias_data()
    Logger.info("Starting determine CLEAN fias data for #{count}")

    # cannot stream db without transaction
    Repo.transaction(fn() ->
       AddressApi.get_unprocessed()
       |> Enum.reduce(0, fn (address, acc) ->
         rows_updated = try_update(address)
         Logger.info("Rows updated in table: #{acc + 1} from #{count}")
         Logger.info("Processed: #{acc + 1} from #{count}")
         acc + 1
       end)
    end)
    Logger.info("Finished")

    {:ok}
  end
  
  @spec try_update(%Address{}) :: integer  

  defp try_update(%Address{address: address_text} = address) do
    rows_updated = 
      DadataApi.get_fias_code(address_text)
      |> log_api_result(address)
      |> update(address)
  end

  @spec log_api_result({:ok, binary} | {:error, binary}, Address.t) :: {:ok, binary} | {:error, binary}

  defp log_api_result({:ok, nil} = result, %Address{address: text} = address) do
    Logger.info(" #{String.slice(text, 0, 50)} marked as NOT FOUND")
    result
  end

  defp log_api_result({:ok, fias_code} = result, %Address{id: id, address: address_text}) do
    Logger.info("Fias code determined (#{fias_code}) for #{address_text}")
    result
  end

  defp log_api_result({:error, reason} = result, %Address{address: address_text}) do
    Logger.warn("Api result failed for #{address_text}: "<> reason)
    result
  end

  @spec update({:ok, binary} | {:error, binary}, Address.t) :: integer

  defp update({:error, reason}, _), do: 0

  defp update({:ok, nil}, %Address{} = address), do: AddressApi.mark_as_not_found(address); 0
  
  defp update({:ok, fias_code}, %Address{} = address) do
    {updated_count, nil} = AddressApi.update_same_addresses(address, fias_code)
    updated_count
  end
end
