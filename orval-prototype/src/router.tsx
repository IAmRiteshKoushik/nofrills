import { createRootRoute, createRoute, createRouter, Outlet } from '@tanstack/react-router'
import { TodoPage } from './routes/todos'

const rootRoute = createRootRoute({
  component: Outlet,
})

const todosRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: TodoPage,
})

const routeTree = rootRoute.addChildren([todosRoute])

export const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
