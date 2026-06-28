defmodule OpencodeClient.Auth do
  @moduledoc false

  @type t :: {:basic, String.t(), String.t()} | {:bearer, String.t()} | nil

  @spec apply(Req.Request.t(), t() | term()) :: Req.Request.t()
  def apply(req, {:basic, username, password}) do
    Req.merge(req, auth: {:basic, username, password})
  end

  def apply(req, {:bearer, token}) do
    Req.merge(req, auth: {:bearer, token})
  end

  def apply(req, _auth), do: req
end
