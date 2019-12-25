defmodule DadataApiTest do

alias AddressProcessor.Dadata.{Api, ApiResult, ApiObjectData}

  use ExUnit.Case
  doctest Api

  test "determine fias data test" do
    address = "г. Одинцово, Одинцовский р-н, Трехгорка, Кутузовская, д.4А, кв.100"

    # making test on real api for simplicity
    assert {:ok, %ApiResult{object: %ApiObjectData{}, suggestion_count: 1 }} = Api.determine_fias_data(address)
  end
  
  test "determine fias data error" do
    address = "ХУЙ"

    # making test on real api for simplicity
    assert {:error, _reason } = Api.determine_fias_data(address)
  end
end
