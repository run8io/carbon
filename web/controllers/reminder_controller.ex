defmodule Carbon.ReminderController do
  use Carbon.Web, :controller

  #import Carbon.ControllerUtils

  alias Carbon.Reminder
  alias Carbon.Event

  def new(conn, %{"account_id" => account_id, "event_id" => event_id}) do
    changeset = Reminder.changeset(%Reminder{})
    conn
    |> assign(:changeset, changeset)
    |> assign(:account_id, account_id)
    |> assign(:event_id, event_id)
    |> render("new.html")
  end

  def create(conn, %{"account_id" => account_id, "event_id" => event_id, "reminder" => reminder_params}) do
    current_user = conn.assigns[:current_user]
    reminder = %Reminder{user: current_user, event: Repo.get(Event, String.to_integer(event_id))}
    changeset = Reminder.create_changeset(reminder, reminder_params)
    case Repo.insert(changeset) do
      {:ok, _reminder} ->
        conn
        |> put_flash(:info, "Reminder created successfully.")
        |> redirect(to: account_event_path(conn, :index, account_id))
      {:error, changeset} ->
        conn
        |> put_flash(:info, "Reminder could not be created.")
        |> assign(:changeset, changeset)
        |> assign(:account_id, account_id)
        |> assign(:event_id, event_id)
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    %{:params => %{"account_id" => account_id, "id" => reminder_id}} = conn
    reminder = Repo.get(Reminder, reminder_id)
    changeset = Reminder.archive_changeset(reminder, %{active: false})
    case Repo.update(changeset) do
      {:ok, reminder} ->
        conn
        |> put_flash(:deleted_reminder, reminder)
        |> redirect(to: account_event_path(conn, :index, account_id))
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_flash(:info, "Failed to delete reminder.")
        |> render(account_event_path(conn, :index, account_id))
    end
  end
  def restore(conn, _params) do
    %{:params => %{"account_id" => account_id, "id" => reminder_id}} = conn
    reminder = Repo.get(Reminder, reminder_id)
    changeset = Reminder.archive_changeset(reminder, %{active: true})
    case Repo.update(changeset) do
      {:ok, _reminder} ->
        conn
        |> redirect(to: account_event_path(conn, :index, account_id))
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_flash(:info, "Failed to restore reminder.")
        |> render(account_event_path(conn, :index, account_id))
    end
  end
end
