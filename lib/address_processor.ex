defmodule AddressProcessor do
  @moduledoc """
    Processing addresses with undefinded fias codes
    uses dadata SUGGESTIONS api
  """

  alias AddressProcessor.AddressProvider.Api, as: AddressApi
  alias AddressProcessor.Dadata.ApiResult
  alias AddressProcessor.Dadata.ApiObjectData
  alias AddressProcessor.Dadata.Api, as: DadataApi
  alias AddressProcessor.AddressProvider.Address 
  require Logger

  @doc "checking addresses one by one"
  def run do

    count = AddressApi.count_without_fias_data()
    Logger.info("Starting determine fias data for #{count}")

    # cannot stream db without transaction
    Repo.transaction(fn() ->
       unprocessed_data = 
       AddressApi.get_unprocessed()
       |> Enum.reduce(0, fn (address, acc) ->
         rows_updated =try_update(address)
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
      DadataApi.determine_fias_data(address_text)
      |> log_api_result(address)
      |> update(address)
  end
  

  defp log_api_result({:ok, %ApiResult{suggestion_count: suggestion_count}} = result, _address) when suggestion_count > 1 do
    Logger.warn("There are more than one suggestion (#{suggestion_count}), returned from dadata service. The first will be used")
    result
  end

  defp log_api_result({:ok, %ApiResult{fias_code: nil}} = result, %Address{address: text} = address) do
    Logger.info(" #{String.slice(text, 0, 50)} marked as NOT FOUND")
    result
  end
 
  defp log_api_result({:ok, %ApiResult{
    suggestion_count: suggestion_count,
    fias_code:        fias_code,
    fias_id:          fias_id 
  }} = result, %Address{address: address_text}) do
    Logger.info("Fias code determined (#{fias_code}) for #{address_text}")
    result
  end 
  
  defp update({:ok, %ApiResult{fias_code: nil}}, address) do
    AddressApi.mark_as_not_found(address)
    0
  end

  defp update({:error, _reason}, %Address{} = address) do
    AddressApi.mark_as_not_found(address)
    0
  end
  
  defp update({:ok, %ApiResult{fias_code: fias_code, fias_id: fias_id}}, address) do
   {rows_updated , nil} =  AddressApi.update_same_addresses(%Address{address: address}, fias_code, fias_id)
   rows_updated
  end
end
