defmodule DadataApiTest do

alias AddressProcessor.Dadata.{Api, ApiResult}

  use ExUnit.Case

  test "determine fias data test" do
    address = "г. Одинцово, Одинцовский р-н, Трехгорка, Кутузовская, д.4А, кв.100"

    # making test on real api for simplicity
    assert {:ok, %ApiResult{suggestion_count: 1 }} = Api.determine_fias_data(address)
  end
 
  test "determine fias data test 2" do
    address = "г. Химки, Гоголя, д.9"

    # making test on real api for simplicity
    assert {:ok, %ApiResult{fias_code: nil, fias_id: nil, suggestion_count: 0}} = Api.determine_fias_data(address)
  end
  
  test "determine fias data error" do
    address = "ХУЙ"

    # making test on real api for simplicity
    assert {:ok, %ApiResult{fias_code: nil, fias_id: nil, suggestion_count: 0}} = Api.determine_fias_data(address)
  end
end


