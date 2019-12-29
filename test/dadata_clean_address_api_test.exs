defmodule DadataCleanAddressApiTest do

alias AddressProcessor.Dadata.CleanApi 

  use ExUnit.Case

  test "determine fias data test 2" do
    address = "г. Химки, Гоголя, д.9"

    # making test on real api for simplicity
    assert {:ok, "50000030000000000090004"} = CleanApi.get_fias_code(address)
  end
  
  test "determine fias data error" do
    address = "ХУЙ"

    # making test on real api for simplicity
    assert {:ok, nil} = CleanApi.get_fias_code(address)
  end
end


