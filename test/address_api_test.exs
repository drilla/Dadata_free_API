defmodule AddressApiTest do
  
  alias AddressProcessor.AddressProvider.Api
  alias AddressProcessor.AddressProvider.Address
  
  use AddressProcessor.Support.EctoCase
  doctest Api


  test "get address without codes" do
    assert  %Address{id: 3} = Api.get_address_without_code()
  end
  
  test "update same address" do
    address = %Address{address: "село Шарапово, 25"}
    assert  {1, _} = Api.update_same_addresses(address, "fake_code", "fake_id")
  end

  test "count undefined fias" do
    count = Api.count_without_fias_data()

    assert count == 63 
  end

  test "mark as not found" do


    Api.mark_as_not_found(%Address{id: 4})

    assert true
  end

end