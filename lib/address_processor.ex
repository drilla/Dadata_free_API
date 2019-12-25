defmodule AddressProcessor do
  @moduledoc """
    Processing addresses with undefinded fias codes
    uses dadata api
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

    # take free address from stream and start loop, while has new addresses

    process_address_loop(AddressApi.get_address_without_code(), 0 , count)

    Logger.info("Finished")

    {:ok}

    # save data
  end

  @doc """
    excluded_ids - accumulating list of ids, which cannot be correctrly processed, due to a missing dada in dadata api
    therefore, we shouldnt ask it from api
  """
  @spec process_address_loop(%Address{}, integer, integer) :: nil  

  defp process_address_loop(address, updated_total_count, total_count)

  defp process_address_loop(nil, _, _), do: nil

  defp process_address_loop(%Address{address: address_text} = address, updated_total_count, total_count) do
    
    rows_updated = 
      DadataApi.determine_fias_data(address_text)
      |> process_api_result(address)

    updated_total_count = updated_total_count + rows_updated
    Logger.info("Updated: #{updated_total_count} from #{total_count}")

    #takes next and so on ...
    process_address_loop(AddressApi.get_address_without_code(), updated_total_count, total_count)
  end
  
  defp process_api_result({:error, "No suggestions available"}, %Address{id: id, address: text} = address) do
    #no suggestions- no actions

    # update table, mark not found
   AddressApi.mark_as_not_found(address)
   Logger.info(" #{String.slice(text, 0, 15)} marked as NOT FOUND")

    0
  end

  defp process_api_result({:ok, %ApiResult{
    suggestion_count: suggestion_count,
    object:           %ApiObjectData{fias_code: fias_code, fias_id: _fias_id} = object 
  }}, %Address{id: id, address: address_text} = address) do

    cond do
      suggestion_count > 1 -> Logger.warn("There are more than one suggestion (#{suggestion_count}), returned from dadata service. The first will be used")
      true                 -> nil
    end
    Logger.info("Fias code and id determined for #{address_text}")
    
    rows_updated = update_addresses(object, address)

    # if object has ho valid fias code, skip it
    cond do
      fias_code === nil ->
        AddressApi.mark_as_not_found(address)
        Logger.info(" #{String.slice(address_text, 0, 15)} marked as NOT FOUND")
        true -> nil
    end

    rows_updated
  end

  defp process_api_result({:error, reason}, %Address{address: address_text}) do
    Logger.warn("Api result for #{address_text}: "<> reason)
    0
  end

  defp update_addresses( %ApiObjectData{fias_code: fias_code, fias_id: fias_id}, %Address{} = address) do
   
    {updated_count, nil} = AddressApi.update_same_addresses(address, fias_code, fias_id)
    case updated_count do
      0     -> nil 
      count -> Logger.info("Updated #{count} addresses")
    end
    updated_count
  end

  defp update_addresses(_, _), do: 0
end
