import { useQueryClient } from '@tanstack/react-query'
import axios from 'axios'
import { useState } from 'react'
import type { FormEvent } from 'react'
import {
  getListTodosQueryKey,
  useCreateTodo,
  useDeleteTodo,
  useListTodos,
  useUpdateTodo,
} from '../api/generated'
import type { Todo } from '../api/generated/models'

export function TodoPage() {
  const queryClient = useQueryClient()
  const [title, setTitle] = useState('')
  const [details, setDetails] = useState('')
  const todosQuery = useListTodos()
  const refreshTodos = () => queryClient.invalidateQueries({ queryKey: getListTodosQueryKey() })
  const createTodo = useCreateTodo({ mutation: { onSuccess: refreshTodos } })
  const updateTodo = useUpdateTodo({ mutation: { onSuccess: refreshTodos } })
  const deleteTodo = useDeleteTodo({ mutation: { onSuccess: refreshTodos } })

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const trimmedTitle = title.trim()
    if (!trimmedTitle) {
      return
    }
    createTodo.mutate(
      { data: { title: trimmedTitle, details: details.trim() } },
      {
        onSuccess: () => {
          setTitle('')
          setDetails('')
        },
      },
    )
  }

  const error = todosQuery.error ?? createTodo.error ?? updateTodo.error ?? deleteTodo.error

  return (
    <main className="page-shell">
      <section className="todo-panel" aria-labelledby="page-title">
        <header className="hero">
          <p className="eyebrow">OpenAPI + Orval</p>
          <h1 id="page-title">Things worth doing.</h1>
          <p className="lede">
            This React screen gets its API functions, types, and TanStack Query hooks from{' '}
            <code>openapi.yaml</code>.
          </p>
        </header>

        <form className="new-todo" onSubmit={submit}>
          <label>
            <span>What needs doing?</span>
            <input
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Try the generated query hooks"
              disabled={createTodo.isPending}
              required
            />
          </label>
          <label>
            <span>Details, if useful</span>
            <input
              value={details}
              onChange={(event) => setDetails(event.target.value)}
              placeholder="Optional"
              disabled={createTodo.isPending}
            />
          </label>
          <button type="submit" disabled={createTodo.isPending}>
            {createTodo.isPending ? 'Adding...' : 'Add TODO'}
          </button>
        </form>

        {error ? <p className="error" role="alert">{readError(error)}</p> : null}

        <section className="todo-list" aria-live="polite" aria-busy={todosQuery.isLoading}>
          <div className="list-heading">
            <h2>Your list</h2>
            <span>{todosQuery.data?.length ?? 0} items</span>
          </div>

          {todosQuery.isLoading ? <p className="empty-state">Loading TODOs...</p> : null}
          {todosQuery.isError ? null : todosQuery.data?.length === 0 ? (
            <p className="empty-state">A quiet list. Add something you want to remember.</p>
          ) : null}
          {todosQuery.data?.map((todo) => (
            <TodoRow
              key={todo.id}
              todo={todo}
              isUpdating={updateTodo.isPending}
              isDeleting={deleteTodo.isPending}
              onToggle={() => updateTodo.mutate({ id: todo.id, data: { completed: !todo.completed } })}
              onDelete={() => deleteTodo.mutate({ id: todo.id })}
            />
          ))}
        </section>
      </section>
    </main>
  )
}

interface TodoRowProps {
  todo: Todo
  isUpdating: boolean
  isDeleting: boolean
  onToggle: () => void
  onDelete: () => void
}

function TodoRow({ todo, isUpdating, isDeleting, onToggle, onDelete }: TodoRowProps) {
  const isBusy = isUpdating || isDeleting

  return (
    <article className={todo.completed ? 'todo todo-complete' : 'todo'}>
      <label className="completion-toggle">
        <input
          type="checkbox"
          checked={todo.completed}
          onChange={onToggle}
          disabled={isBusy}
          aria-label={`Mark ${todo.title} as ${todo.completed ? 'incomplete' : 'complete'}`}
        />
        <span aria-hidden="true" />
      </label>
      <div className="todo-copy">
        <h3>{todo.title}</h3>
        {todo.details ? <p>{todo.details}</p> : null}
      </div>
      <button className="delete-button" type="button" onClick={onDelete} disabled={isBusy}>
        Delete
      </button>
    </article>
  )
}

function readError(error: unknown): string {
  if (axios.isAxiosError<{ error?: string }>(error)) {
    return error.response?.data?.error ?? 'The API did not accept that request.'
  }
  return 'Something went wrong while talking to the API.'
}
