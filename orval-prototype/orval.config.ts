import { defineConfig } from 'orval'

export default defineConfig({
  todoApi: {
    input: {
      target: './openapi.yaml',
    },
    output: {
      mode: 'tags-split',
      target: './src/api/generated/todo-api.ts',
      schemas: './src/api/generated/models',
      client: 'react-query',
      httpClient: 'axios',
      clean: true,
      override: {
        mutator: {
          path: './src/api/axios-instance.ts',
          name: 'apiRequest',
        },
      },
    },
  },
})
