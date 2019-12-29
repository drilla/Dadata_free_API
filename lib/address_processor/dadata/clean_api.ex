defmodule AddressProcessor.Dadata.CleanApi do
  use HTTPoison.Base

  alias AddressProcessor.Dadata.ApiResult 
  alias AddressProcessor.Dadata.ApiObjectData 
  require Logger

  @api_token Application.get_env(:address_processor, :dadata_api_key)
  @api_url "https://dadata.ru/api/v2/clean-record/address"
  @dadata_csrf_token Application.get_env(:address_processor, :dadata_csrf_token)

  def get_fias_code(address) when is_binary(address) do
    result= 
      address
      |> do_request()
      |> get_result()

    case result do
      {:error, :too_many_requests} -> 
        Process.sleep(1000)
        get_fias_code(address)

      result -> result
    end
  end

  defp do_request(address) do
    body = [[address]] |> Poison.encode!()

    options = [hackney: [cookie: [
      "csrftoken=#{@dadata_csrf_token}; logged_in=true path=/; domain=.dadata.ru;",
      "ddg1=16CC18ED56A2DBD4AE596D886CDE030BA998FC9A; path=/; domain=.dadata.ru;"
      ]]]
    headers = %{
      "Content-Type"  => "application/json",
      "Accept"        => "application/json",
      "Authorization" => "Token #{@api_token}",
      "x-csrftoken"   => @dadata_csrf_token  
    }

    post(@api_url, body, headers, options)
  end

  defp get_result({:ok, %HTTPoison.Response{body: response_body, status_code: 200} }) do
    case Poison.decode(response_body) do
      {:error, reason}                     -> {:error, reason}
      {:ok, [%{"fias_code" => nil}]}       -> {:ok, nil}
      {:ok, [%{"fias_code" => fias_code}]} -> {:ok, fias_code} 
    end 
  end
  
  defp get_result({:ok, %HTTPoison.Response{status_code: 429} }), do: {:error, :too_many_requests}

  defp get_result({:error, reason}) when is_binary(reason), do: {:error, reason}
  defp get_result({:error, reason}), do: get_result({:error, inspect(reason)})
end