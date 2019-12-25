defmodule AddressProcessor.AddressProvider.Repo do
  use Ecto.Repo,
    otp_app: :address_processor,
    adapter: Ecto.Adapters.MyXQL
end


