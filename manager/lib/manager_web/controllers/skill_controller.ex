defmodule Time_managerWeb.SkillController do
  use Time_managerWeb, :controller

  alias Time_manager.Account

  def index(conn, _params) do
    skills = Account.list_skills()

    json(conn, %{
      data: Enum.map(skills, &data/1)
    })
  end

  def show(conn, %{"skillID" => skill_id}) do
    skill = Account.get_skill!(skill_id)

    json(conn, %{
      data: data(skill)
    })
  end

  def create(conn, %{"label" => label}) do
    case Account.create_skill(%{label: label}) do
      {:ok, skill} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: data(skill)
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          errors: errors_from_changeset(changeset)
        })
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Le champ label est obligatoire."
    })
  end

  def update(conn, %{"skillID" => skill_id, "label" => label}) do
    skill = Account.get_skill!(skill_id)

    case Account.update_skill(skill, %{label: label}) do
      {:ok, updated_skill} ->
        json(conn, %{
          data: data(updated_skill)
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          errors: errors_from_changeset(changeset)
        })
    end
  end

  def delete(conn, %{"skillID" => skill_id}) do
    skill = Account.get_skill!(skill_id)

    case Account.delete_skill(skill) do
      {:ok, _skill} ->
        send_resp(conn, :no_content, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          errors: errors_from_changeset(changeset)
        })
    end
  end

  defp data(skill) do
    %{
      id: skill.id,
      label: skill.label
    }
  end

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
