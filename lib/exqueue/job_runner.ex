defmodule Exqueue.JobRunner do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_job(job) do
    GenServer.cast(__MODULE__, {:register_job, job})
  end

  def handle_cast({:register_job, job}, state) do
    # NOTE: Run jobs concurrently later
    #spawn_link fn ->
      job
      |> run_job
      |> process_result
    #end

    {:noreply, state}
  end

  defp run_job(job), do: Exqueue.JobProcess.run(job)

  defp process_result({:job_was_successful, job}) do
    Exqueue.Peristance.mark_as_successful(job)
    Exqueue.JobEvent.finished(job)
  end

  defp process_result({:job_has_failed, job, error}) do
    Exqueue.Peristance.mark_as_failed(job)
    Logger.error "Job ##{job.id}: #{inspect(job.worker)}.perform(#{inspect(job.opts)}) failed with error: #{inspect(error)}"
    Exqueue.JobEvent.failed(job)
  end
end
