defmodule Time_manager.Auth do
  use Joken.Config

  @token_lifetime 60 * 60 * 24 * 30

  @impl true
  def token_config do
    default_claims(
      skip: [:aud],
      default_exp: @token_lifetime
    )
    |> add_claim("user_id", nil, &is_integer/1)
    |> add_claim("role", nil, &is_binary/1)
    |> add_claim("csrf_token", nil, &is_binary/1)
  end

  def generate_token(user_id, role, csrf_token) do
    generate_and_sign(
      %{
        "user_id" => user_id,
        "role" => role,
        "csrf_token" => csrf_token
      },
      signer()
    )
  end

  def verify_token(token) do
    verify_and_validate(token, signer())
  end

  def generate_csrf_token do
    :crypto.strong_rand_bytes(37)
    |> Base.url_encode64(padding: false)
  end

  defp signer do
    Joken.Signer.create(
      "HS256",
      jwt_secret()
    )
  end

  defp jwt_secret do
    System.get_env(
      "JWT_SECRET",
      "time-manager-development-jwt-secret-change-me"
    )
  end
end
