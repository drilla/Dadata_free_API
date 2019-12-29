defmodule AddressProcessor.Dadata.Api do
  use HTTPoison.Base

  alias AddressProcessor.Dadata.ApiResult 
  alias AddressProcessor.Dadata.ApiObjectData 
  require Logger

  @api_token Application.get_env(:address_processor, :dadata_api_key)
  @api_delay_after_request 50
  @api_url "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address"

  @spec determine_fias_data(binary) :: {:ok, ApiResult.t} | {:error, binary}
  def determine_fias_data(address) when is_binary(address) do

    body = %{
      "query"     => address,
      "count"     => 10, # count 1 is restricted for free usage
      "locations" => [%{"region" => "московская"}] #restrict search area
    } |> Poison.encode!()

    headers = %{
      "Content-Type"  => "application/json",
      "Accept"        =>  "application/json",
      "Authorization" => "Token #{@api_token}"
    }

    result = post(@api_url, body, headers)
    case result do 
        {:ok, %HTTPoison.Response{body: response_body, status_code: 200} } -> 
          suggestions = response_body 
          |> Poison.decode!()
          |> extrude_suggestions()

          case suggestions do
            [] -> 
              {:ok, %ApiResult{}} 
            
            [_ | _] ->
              record = get_first_correct(suggestions)

              case record do
                nil -> 
                  {:ok, %ApiResult{}}

                %{"data" => %{"fias_id" => fias_id, "fias_code" => fias_code}} ->
                   Process.sleep(@api_delay_after_request)
                   {:ok, %ApiResult{
                            suggestion_count: Enum.count(suggestions),
                            fias_id: fias_id,
                            fias_code: fias_code}
                   }      
              end
          end
          
        {:ok, %HTTPoison.Response{status_code: 429} } ->
            #too many requests, wait and repeat
            Process.sleep(1000)
            determine_fias_data(address)
      
        {:error, error} -> 
          Logger.error(inspect(error))
          {:error, inspect(error)}
    end
  end

  def extrude_suggestions(%{"suggestions" => suggestions}), do: suggestions
  def extrude_suggestions(_), do: []
 
  defp get_first_correct([]), do: nil
  
  defp get_first_correct([ %{"data" => %{"fias_code" => fias_code}} = head | _tail ]) when is_binary(fias_code) do
    head
  end

  defp get_first_correct([_head | tail]) do
    get_first_correct(tail)
  end
end