defmodule AddressProcessor.Dadata.Api do
  use HTTPoison.Base

  alias AddressProcessor.Dadata.ApiResult 
  alias AddressProcessor.Dadata.ApiObjectData 
  require Logger

  @api_token Application.get_env(:address_processor, :dadata_api_key)
  @api_delay_after_request 50
  @api_url "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address"

  def determine_fias_data(address) when is_binary(address) do

    body = %{
      "query"     => address,
      "count"     => 2, # count 1 is restricted for free usage
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
              {:error, "No suggestions available"}
              
             _ ->
              [first | _] = suggestions
                %{"data" => %{"fias_id" => fias_id, "fias_code" => fias_code, "kladr_id" => kladr_id}} = first 

              #substitute fias code by kladr, if not present
              fias_code = 
                case fias_code do
                  nil -> kladr_id
                  _   -> fias_code
                end  
                
            Process.sleep(@api_delay_after_request)
              {:ok, %ApiResult{
                suggestion_count: Enum.count(suggestions),
                object:  %ApiObjectData{fias_id: fias_id, fias_code: fias_code} 
              }}
          end
          {:ok, %HTTPoison.Response{status_code: 429} } ->
            #too many requests, wait and repeat
            Process.sleep(1000)
            determine_fias_data(address)
      {:error, error} -> 
        Logger.error(inspect(error))
        error
    end
  end

  def extrude_suggestions(%{"suggestions" => suggestions}), do: suggestions
  def extrude_suggestions(_), do: []
  
end